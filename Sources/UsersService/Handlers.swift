import MySQL
import Kitura
import LoggerAPI
import Foundation
import SwiftyJSON

// MARK: - Handlers

public class Handlers {

    // MARK: Properties

    let dataAccessor: UserMySQLDataAccessorProtocol
    let accountKitClient: AccountKitClient

    // MARK: Initializer

    public init(dataAccessor: UserMySQLDataAccessorProtocol, accountKitClient: AccountKitClient) {
        self.dataAccessor = dataAccessor
        self.accountKitClient = accountKitClient
    }

    // MARK: OPTIONS

    public func getOptions(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
        response.headers["Access-Control-Allow-Methods"] = "GET,POST,DELETE,OPTIONS,PUT"
        try response.status(.OK).end()
    }

    // MARK: POST

    public func login(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
        // Ensure a value for `code` exists in the request's query parameters.
        // Use the `accountKitClient` to perform a code-to-token exchange.
        // Specify a completion handler that parses the response for the code-to-token exchange.
        // If the request was successful, then extract the `id` value (you can ignore the `access_token`).
        // Otherwise print an error message saying the `id` could not be found.
    }
}
