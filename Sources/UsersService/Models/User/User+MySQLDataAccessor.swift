import MySQL

// MARK: - UserMySQLDataAccessorProtocol

public protocol UserMySQLDataAccessorProtocol {
    func getUsers(withID id: String) throws -> [User]?
    func getUsers() throws -> [User]?
}

// MARK: - UserMySQLDataAccessor: UserMySQLDataAccessorProtocol

public class UserMySQLDataAccessor: UserMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    let selectUsers = MySQLQueryBuilder()
            .select(fields: ["id", "name", "location",
            "photo_url", "created_at", "updated_at"], table: "users")

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: Queries

    public func getUsers(withID id: String) throws -> [User]? {
        let query = "SELECT * " +
                    "FROM users " +
                    "WHERE id=\(id)"
        let result = try execute(query: query)
        let users = result.toUsers()
        return (users.count == 0) ? nil : users
    }

    public func getUsers() throws -> [User]? {
        let result = try execute(builder: selectUsers)
        let users = result.toUsers()
        return (users.count == 0) ? nil : users
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
