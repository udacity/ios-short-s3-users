import MySQL

// MARK: - UserMySQLDataAccessorProtocol

public protocol UserMySQLDataAccessorProtocol {
    func getUsers(withID id: String) throws -> [User]?
    func getUsers() throws -> [User]?
    func insertStubUser(withID id: String) throws -> Bool
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

    public func getUsers(withID id: String) throws -> [User]? {
        let selectUser = MySQLQueryBuilder()
                .select(fields: ["id", "name", "location", "photo_url", "created_at", "updated_at"], table: "users")
                .wheres(statement: "WHERE Id=?", parameters: id)

        let result = try execute(builder: selectUser)
        let users = result.toUsers()
        return (users.count == 0) ? nil : users
    }

    public func getUsers() throws -> [User]? {
        let selectUsers = MySQLQueryBuilder()
                .select(fields: ["id", "name", "location", "photo_url", "created_at", "updated_at"], table: "users")

        let result = try execute(builder: selectUsers)
        let users = result.toUsers()
        return (users.count == 0) ? nil : users
    }

    // Insert a stub user with only the id. If the user already exists, return false.
    public func insertStubUser(withID id: String) throws -> Bool {
        return true
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func execute(query: String) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(query: query)
    }
}
