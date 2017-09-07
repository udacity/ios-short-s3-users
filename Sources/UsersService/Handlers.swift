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
            Log.error("Cannot initialize body parameters: id. id is a JSON array of strings (user ids) to filter.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: id. id is a JSON array of strings (user ids) to filter."]))
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
            Log.error("Cannot initialize query parameter: code. code should be a valid AccountKit authorization code.")
            try response.send(json: JSON(["message": "Cannot initialize query parameter: code. code should be a valid AccountKit authorization code."]))
                        .status(.badRequest).end()
            return
        }

        accountKitClient.getAccessToken(withAuthCode: code) { (data, error) in
            guard let data = data, let parsedData = try JSONSerialization.jsonObject(with: data) as? [String:Any] else {
                Log.error("Request for AccountKit access token failed. Error: \(error?.localizedDescription ?? "nil").")
                try response.send(json: JSON(["message": "Request for AccountKit access token failed."]))
                            .status(.internalServerError).end()
                return
            }

            guard let id = parsedData["id"] as? String else {
                Log.error("Unable to initialize AccountKit id from \(parsedData).")
                try response.send(json: JSON(["message": "Unable to initialize AccountKit id from \(parsedData)."]))
                            .status(.internalServerError).end()
                return
            }

            var stubUser = User()
            stubUser.id = id

            let _ = try self.dataAccessor.upsertStubUser(stubUser)

            guard let users = try self.dataAccessor.getUsers(withIDs: [id], pageSize: 1, pageNumber: 1), users.count == 1 else {
                Log.error("Unable to initialize user from id.")
                try response.send(json: JSON(["message": "Unable to initialize user from id."]))
                            .status(.internalServerError).end()
                return
            }

            let missingParameters = users[0].validateParameters(
                ["id", "name", "location", "photo_url"])
            let isNewUser = missingParameters.count != 0
            Log.info("\(isNewUser)")

            do {
                let payload: [String: Any] = [
                    "iss": "http://gamenight.udacity.com",
                    "exp": Date().append(months: 1).timeIntervalSince1970,
                    "sub": "users microservice",
                    "perms": isNewUser ? "usersProfile" : "usersAll,activities,events,friends",
                    "user": id
                ]
                let jwt = try self.jwtComposer.createSignedTokenWithPayload(payload)
                try response.send(json: JSON(["jwt": jwt, "id": id])).status(.OK).end()
            } catch {
                Log.error("Unable to generate signed JWT.")
                try response.send(json: JSON(["message": "Unable to generate signed JWT."]))
                            .status(.internalServerError).end()
            }
        }
    }

    public func logout(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        // TODO: Add implementation.
    }

    // MARK: PUT

    public func updateProfile(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.userInfo["user_id"] as? String else {
            Log.error("Cannot access current user's id.")
            try response.send(json: JSON(["message": "Cannot access current user's id."]))
                        .status(.internalServerError).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
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
            Log.error("Unable to initialize parameters from request body: \(missingParameters).")
            try response.send(json: JSON(["message": "Unable to initialize parameters from request body: \(missingParameters)."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.updateUser(updateUser)

        if success {
            try response.send(json: JSON(["message": "User profile updated."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }

    public func updateFavorites(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.userInfo["user_id"] as? String else {
            Log.error("Cannot access current user's id.")
            try response.send(json: JSON(["message": "Cannot access current user's id."]))
                        .status(.internalServerError).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let favoriteActivitiesJSON = json["activities"].array else {
            Log.error("Cannot initialize body parameters: activities. activities is a JSON array of strings (activity ids) to favorite.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: activities. activities is a JSON array of strings (activity ids) to favorite."]))
                        .status(.badRequest).end()
            return
        }

        var favorites: [Int] = []
        for favoriteActivityJSON in favoriteActivitiesJSON {
        if let favoriteString = favoriteActivityJSON.string, let favorite = Int(favoriteString) {
                favorites.append(favorite)
            }
        }
        guard favorites.count > 0 else {
            Log.error("Cannot initialize body parameters: activities. activities is a JSON array of strings (activity ids) to favorite.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: activities. activities is a JSON array of strings (activity ids) to favorite."]))
                        .status(.badRequest).end()
            return
        }

        var updateUser = User()
        updateUser.id = id

        let success = try dataAccessor.updateFavoritesForUser(updateUser, favorites: favorites)

        if success {
            try response.send(json: JSON(["message": "User favorites updated."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }
}
