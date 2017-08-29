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

    public func getUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("body contains invalid JSON")
            try response.send(json: JSON(["message": "body is missing JSON or JSON is invalid"]))
                        .status(.badRequest).end()
            return
        }

        let ids = json["ids"].arrayValue.map({$0.stringValue})

        guard ids.count > 0 else {
            Log.error("request body is missing array of user ids")
            try response.send(json: JSON(["message": "request body is missing array of user ids"]))
                        .status(.badRequest).end()
            return
        }

        let users = try dataAccessor.getUsers(withIDs: ids)

        if users == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: users!.toJSON()).status(.OK).end()
    }

    public func getProfile(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        var users: [User]?

        if let id = request.userInfo["user_id"] as? String {
            users = try dataAccessor.getUsers(withID: id)
        }

        if users == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: users!.toJSON()).status(.OK).end()
    }

    public func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
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
                Log.error("data is nil, error is \(error?.localizedDescription ?? "nil")")
                try response.send(json: JSON(["message": "could not get AccountKit access token"]))
                            .status(.internalServerError).end()
                return
            }

            guard let parsedData = try JSONSerialization.jsonObject(with: data) as? [String:Any],
                let id = parsedData["id"] as? String else {
                    Log.error("could not find AccountKit id")
                    try response.send(json: JSON(["message": "could not find AccountKit id"]))
                                .status(.internalServerError).end()
                    return
            }

            let stubUser = User(
                id: id,
                name: nil,
                location: nil,
                photoURL: nil,
                favoriteActivities: nil,
                createdAt: nil, updatedAt: nil)

            let isNewUser = try self.dataAccessor.upsertStubUser(stubUser)

            do {
                let jwt = try self.jwtComposer.createSignedTokenWithPayload([
                    "iss": "http://gamenight.udacity.com",
                    "exp": Date().append(months: 1).timeIntervalSince1970,
                    "sub": "users microservice",
                    "perms": isNewUser ? "usersProfile" : "usersAll,activities,events,friends",
                    "user": id
                ])
                try response.send(json: JSON(["jwt": jwt, "id": id])).status(.OK).end()
            } catch {
                Log.error("could not create signed jwt")
                try response.status(.internalServerError).end()
            }
        }
    }

    // MARK: PUT

    public func updateProfile(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.userInfo["user_id"] as? String else {
            Log.error("could not get user_id from jwt")
            try response.send(json: JSON(["message": "could not get user_id from jwt"]))
                        .status(.internalServerError).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("body contains invalid JSON")
            Log.info("\(String(describing: request.body))")
            try response.send(json: JSON(["message": "body is missing JSON or JSON is invalid"]))
                        .status(.badRequest).end()
            return
        }

        let updateUser = User(
            id: id,
            name: json["name"].string,
            location: json["location"].string,
            photoURL: json["photo_url"].string,
            favoriteActivities: nil,
            createdAt: nil, updatedAt: nil)

        let missingParameters = updateUser.validateParameters(
            ["id", "name", "location", "photo_url"])

        if missingParameters.count != 0 {
            Log.error("parameters missing \(missingParameters)")
            try response.send(json: JSON(["message": "parameters missing \(missingParameters)"]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.updateUser(updateUser)

        if success {
            try response.send(json: JSON(["message": "user updated"])).status(.OK).end()
        }

        try response.status(.notModified).end()
    }

    public func updateFavorites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }
}
