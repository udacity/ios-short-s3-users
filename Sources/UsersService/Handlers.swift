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

    public func searchUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let idFilter = json["id"].array else {
            Log.error("Cannot initialize body parameters: id. id is a JSON array of strings (event ids) to filter.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: id. id is a JSON array of strings (event ids) to filter."]))
                        .status(.badRequest).end()
            return
        }

        let ids = idFilter.map({$0.stringValue})
        let users = try dataAccessor.getUsers(withIDs: ids, pageSize: pageSize, pageNumber: pageNumber)

        if users == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: users!.toJSON()).status(.OK).end()
    }

    public func getCurrentUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.userInfo["user_id"] as? String else {
            Log.error("Cannot access current user's id.")
            try response.send(json: JSON(["message": "Cannot access current user's id."]))
                        .status(.internalServerError).end()
            return
        }

        let users = try dataAccessor.getUsers(withIDs: [id], pageSize: 1, pageNumber: 1)

        if users == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: users!.toJSON()).status(.OK).end()
    }

    public func getUsers(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        var users: [User]?
        let id = request.parameters["id"]

        if let id = id {
            users = try dataAccessor.getUsers(withIDs: [id], pageSize: 1, pageNumber: 1)
        } else {
            users = try dataAccessor.getUsers(pageSize: pageSize, pageNumber: pageNumber)
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

    public func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
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
