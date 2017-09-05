import MySQL
import LoggerAPI

// MARK: - UserMySQLDataAccessorProtocol

public protocol UserMySQLDataAccessorProtocol {
    func getUsers(withIDs ids: [String], pageSize: Int, pageNumber: Int) throws -> [User]?
    func getUsers(pageSize: Int, pageNumber: Int) throws -> [User]?
    func upsertStubUser(_ user: User) throws -> Bool
    func updateUser(_ user: User) throws -> Bool
}

// MARK: - UserMySQLDataAccessor: UserMySQLDataAccessorProtocol

public class UserMySQLDataAccessor: UserMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: Queries

    public func getUsers(withIDs ids: [String], pageSize: Int = 10, pageNumber: Int = 1) throws -> [User]? {
        let selectUsersIDs = MySQLQueryBuilder()
            .select(fields: ["id"], table: "users")
            .wheres(statement:"id IN (?)", parameters: ids)

        // Select ids and apply pagination before joins
        let simpleResults = try execute(builder: selectUsersIDs)
        simpleResults.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))
        let simpleUsers = simpleResults.toUsers(pageSize: pageSize)
        let newIDs = simpleUsers.map({String($0.id!)!})

        var users = [User]()

        // Once the ids are determind, perform the joins
        if newIDs.count > 0 {
            let selectUser = MySQLQueryBuilder()
                    .select(fields: ["id", "name", "location", "photo_url", "created_at", "updated_at"], table: "users")
            let selectFavorites = MySQLQueryBuilder()
                    .select(fields: ["user_id", "activity_id"], table: "favorites")
            let selectQuery = selectUser.wheres(statement: "id IN (?)", parameters: newIDs)
                    .join(builder: selectFavorites, from: "id", to: "user_id", type: .LeftJoin)

            let result = try execute(builder: selectQuery)
            users = result.toUsers()
        }

        return (users.count == 0) ? nil : users
    }

    public func getUsers(pageSize: Int = 10, pageNumber: Int = 1) throws -> [User]? {
        let selectUsersIDs = MySQLQueryBuilder()
            .select(fields: ["id"], table: "users")

        // Select ids and apply pagination before joins
        let simpleResults = try execute(builder: selectUsersIDs)
        simpleResults.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))
        let simpleUsers = simpleResults.toUsers(pageSize: pageSize)
        let ids = simpleUsers.map({String($0.id!)!})

        var users = [User]()

        // Once the ids are determind, perform the joins
        if ids.count > 0 {
            let selectUser = MySQLQueryBuilder()
                    .select(fields: ["id", "name", "location", "photo_url", "created_at", "updated_at"], table: "users")
            let selectFavorites = MySQLQueryBuilder()
                    .select(fields: ["user_id", "activity_id"], table: "favorites")
            let selectQuery = selectUser.wheres(statement: "id IN (?)", parameters: ids)
                    .join(builder: selectFavorites, from: "id", to: "user_id", type: .LeftJoin)

            let result = try execute(builder: selectQuery)
            users = result.toUsers()
        }

        return (users.count == 0) ? nil : users
    }

    // Upsert a stub user. If the user already exists, then nothing is updated and false is returned.
    public func upsertStubUser(_ user: User) throws -> Bool {
        let upsertUser = MySQLQueryBuilder()
                .upsert(data: user.toMySQLRow(), table: "users")

        let result = try execute(builder: upsertUser)
        return result.affectedRows > 0
    }

    public func updateUser(_ user: User) throws -> Bool {
        let updateQuery = MySQLQueryBuilder()
                .update(data: user.toMySQLRow(), table: "users")
                .wheres(statement: "Id=?", parameters: "\(user.id!)")

        let result = try execute(builder: updateQuery)
        return result.affectedRows > 0
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func cacluateOffset(pageSize: Int, pageNumber: Int) -> Int64 {
        return Int64(pageNumber > 1 ? pageSize * (pageNumber - 1) : 0)
    }

    public func isConnected() -> Bool {
        do {
            let connection = try pool.getConnection()
            defer { pool.releaseConnection(connection!) }
        } catch {
            return false
        }
        return true
    }
}
