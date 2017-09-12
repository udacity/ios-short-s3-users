import MySQL
import LoggerAPI

// MARK: - UserMySQLDataAccessorProtocol

public protocol UserMySQLDataAccessorProtocol {
    func getUsers(withIDs ids: [String], pageSize: Int, pageNumber: Int) throws -> [User]?
    func getUsers(pageSize: Int, pageNumber: Int) throws -> [User]?
    func upsertStubUser(_ user: User) throws -> Bool
    func updateUser(_ user: User) throws -> Bool
    func updateFavoritesForUser(_ user: User, favorites: [Int]) throws -> Bool
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
        return nil
    }

    public func getUsers(pageSize: Int = 10, pageNumber: Int = 1) throws -> [User]? {
        return nil
    }

    // Upsert a stub user. If the user already exists, then nothing is updated and false is returned.
    public func upsertStubUser(_ user: User) throws -> Bool {
        return false
    }

    public func updateUser(_ user: User) throws -> Bool {
        return false
    }

    public func updateFavoritesForUser(_ user: User, favorites: [Int]) throws -> Bool {
        return false
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
