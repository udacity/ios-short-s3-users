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
    let jwtComposer: JWTComposer

    // MARK: Initializer

    public init(dataAccessor: UserMySQLDataAccessorProtocol, accountKitClient: AccountKitClient, jwtComposer: JWTComposer) {
        self.dataAccessor = dataAccessor
        self.accountKitClient = accountKitClient
        self.jwtComposer = jwtComposer
    }

    // MARK: OPTIONS

    public func getOptions(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
        response.headers["Access-Control-Allow-Methods"] = "GET,POST,DELETE,OPTIONS,PUT"
        try response.status(.OK).end()
    }

    // MARK: GET

    public func getProfile(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }

    public func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }

    public func getUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        let id = request.parameters["id"]

        var users: [User]?

        if let id = id {
            users = try dataAccessor.getUsers(withID: id)
        } else {
            users = try dataAccessor.getUsers()
        }

        if users == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: users!.toJSON()).status(.OK).end()
    }

    // MARK: POST

    public func login(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let code = request.queryParameters["code"] else {
            Log.error("code (query parameter) missing")
            try response.send(json: JSON(["message": "code (query parameter) missing"]))
                        .status(.badRequest).end()
            return
        }

        accountKitClient.getAccessToken(withAuthCode: code) { (data, error) in
            guard let data = data else {
                Log.error("data is nil, error: \(error?.localizedDescription ?? "nil")")
                try response.send(json: JSON(["message": "could not get AccountKit access token"]))
                            .status(.internalServerError).end()
                return
            }

            if let parsedData = try JSONSerialization.jsonObject(with: data) as? [String:Any], let id = parsedData["id"] as? String {
                let jwt = self.jwtComposer.createSignedTokenWithPayload([
                    "issuer": "com.udacity.gamenight",
                    "issuedAt": Date().timeIntervalSince1970,
                    "expiration": Date().append(months: 1).timeIntervalSince1970
                ]) ?? ""
                try response.send(json: JSON(["jwt": jwt, "id": id])).status(.OK).end()
            } else {
                Log.error("could not find accountkit id")
                try response.status(.noContent).end()
            }
        }
    }

    // MARK: PUT

    public func updateProfile(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }

    public func updateFavorites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }
}
