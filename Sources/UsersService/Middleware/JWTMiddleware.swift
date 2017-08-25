import Kitura
import KituraNet
import LoggerAPI
import SwiftyJSON
import PerfectCrypto

// MARK: - Permission

public enum Permission: String {
    case usersProfile, usersFull, activities, events, friends, admin
}

// MARK: - JWTMiddleware: RouterMiddleware

public class JWTMiddleware: RouterMiddleware {

    // MARK: Properties

    let jwtComposer: JWTComposer
    let permissions: [Permission]

    // MARK: Initializer

    public init(jwtComposer: JWTComposer, permissions: [Permission]) {
        self.jwtComposer = jwtComposer
        self.permissions = permissions
    }

    // MARK: JWTMiddleware

    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Swift.Void) {

        guard let signedJWTToken = extractSignedTokenFromRequest(request) else {
            sendResponse(response, withStatusCode: .badRequest, withMessage: "auth header is invalid; use format 'Authorization: Bearer [jwt]")
            return
        }

        do {

            let jwt = try jwtComposer.getVerifiedJWTFromSignedToken(signedJWTToken)
            try jwtComposer.verifyReservedClaimsForJWT(jwt, iss: "http://gamenight.udacity.com", sub: "users microservice")
            try jwtComposer.verifyPrivateClaimsForJWT(jwt) { payload in

                var invalidClaims = [String]()

                guard let perms = payload["perms"] as? String else {
                    Log.info("permission denied; perms claim is missing")
                    return ["perms"]
                }

                for permission in permissions {
                    if perms.contains("\(permission.rawValue)") {
                        Log.info("permission granted: \(permission.rawValue)")
                        return []
                    }
                }

                if perms.contains("admin") {
                    Log.info("permission granted: admin")
                } else {
                    Log.info("permission denied; need one of these \(permissions)")
                    invalidClaims.append("perms")
                }

                return invalidClaims
            }

        } catch JWTError.missingPublicKey {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "public key is nil")
        } catch JWTError.cannotCreateJWT {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "cannot create JWT")
        } catch JWTError.cannotVerifyAlgAndKey {
            sendResponse(response, withStatusCode: .badRequest, withMessage: "cannot verify jwt alg and key")
        } catch JWTError.invalidPayload(let message) {
            sendResponse(response, withStatusCode: .badRequest, withMessage: "invalid payload: \(message)")
        } catch {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "failed to verify JWT")
        }

        next()
    }

    // MARK: Utility

    private func sendResponse(_ response: RouterResponse, withStatusCode statusCode: HTTPStatusCode, withMessage message: String) {
        do {
            try response.send(json: JSON(["message": "\(message)"]))
                        .status(statusCode).end()
        } catch {
            Log.error("failed to send response")
        }
    }

    private func extractSignedTokenFromRequest(_ request: RouterRequest) -> String? {
        guard let authHeader = request.headers["Authorization"] else {
            Log.error("auth header is missing")
            return nil
        }

        let authHeaderComponents = authHeader.components(separatedBy: " ")

        if authHeaderComponents.count < 2 || authHeaderComponents[0] != "Bearer" {
            Log.error("auth header is invalid; use format 'Authorization: Bearer [jwt]'")
            return nil
        }

        return authHeaderComponents[1]
    }
}