import Kitura
import KituraNet
import LoggerAPI
import SwiftyJSON
import PerfectCrypto

// MARK: - Permission

public enum Permission: String {
    case usersProfile, usersAll, activities, events, friends, admin
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
            sendResponse(response, withStatusCode: .badRequest, withMessage: "Auth header is invalid; Use format 'Authorization: Bearer [signed-jwt]'.")
            return
        }

        do {
            let jwtVerifier = try jwtComposer.getJWTVerifierWithSignedToken(signedJWTToken)
            try jwtComposer.verifyAlgorithmAndKeyForJWT(jwtVerifier)
            try jwtComposer.verifyReservedClaimsForJWT(jwtVerifier, iss: "http://gamenight.udacity.com", sub: "users microservice")
            try jwtComposer.invalidPrivateClaimsForJWT(jwtVerifier) { payload in

                guard let perms = payload["perms"] as? String else {
                    Log.debug("JWT is missing private claim for perms.")
                    return ["perms"]
                }

                for permission in permissions {
                    if perms.contains("\(permission.rawValue)") {
                        return []
                    }
                }

                if perms.contains("admin") {
                    return []
                }

                Log.debug("JWT has invalid private claim: perms. perms should be one of these \(permissions).")
                return ["perms"]
            }
            request.userInfo["user_id"] = jwtVerifier.payload["user"]
        } catch JWTError.missingPublicKey {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "Public key is nil.")
            return
        } catch JWTError.cannotCreateJWT {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "Cannot create JWT.")
            return
        } catch JWTError.cannotVerifyAlgAndKey {
            sendResponse(response, withStatusCode: .badRequest, withMessage: "Cannot verify JWT alg and key.")
            return
        } catch JWTError.invalidPayload(let message) {
            sendResponse(response, withStatusCode: .badRequest, withMessage: "Invalid JWT payload: \(message).")
            return
        } catch {
            sendResponse(response, withStatusCode: .internalServerError, withMessage: "Failed to verify JWT.")
            return
        }

        next()
    }

    // MARK: Utility

    private func sendResponse(_ response: RouterResponse, withStatusCode statusCode: HTTPStatusCode, withMessage message: String) {
        do {
            try response.send(json: JSON(["message": "\(message)"]))
                        .status(statusCode).end()
            return
        } catch {
            Log.error("Failed to send response")
        }
    }

    private func extractSignedTokenFromRequest(_ request: RouterRequest) -> String? {
        guard let authHeader = request.headers["Authorization"] else {
            Log.error("Auth header is missing.")
            return nil
        }

        let authHeaderComponents = authHeader.components(separatedBy: " ")

        if authHeaderComponents.count < 2 || authHeaderComponents[0] != "Bearer" {
            return nil
        }

        return authHeaderComponents[1]
    }
}
