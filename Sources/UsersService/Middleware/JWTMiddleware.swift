import Kitura
import LoggerAPI
import SwiftyJSON
import PerfectCrypto

// MARK: - JWTMiddleware: RouterMiddleware

public class JWTMiddleware: RouterMiddleware {

    // MARK: Properties

    let jwtComposer: JWTComposer

    // MARK: Initializer

    public init(jwtComposer: JWTComposer) {
        self.jwtComposer = jwtComposer
    }

    // MARK: JWTMiddleware

    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Swift.Void) {
        do {
            guard let authHeader = request.headers["Authorization"] else {
                Log.error("authorization header is missing")
                try response.send(json: JSON(["message": "authorization header is missing"]))
                            .status(.badRequest).end()
                return
            }

            let authHeaderComponents = authHeader.components(separatedBy: " ")
            if authHeaderComponents.count < 2 || authHeaderComponents[0] != "Bearer" {
                Log.error("authorization header is invalid")
                try response.send(json: JSON(["message": "authorization header is invalid; use format 'Authorization: Bearer [jwt]'"]))
                            .status(.badRequest).end()
                return
            }

            let signedJWTToken = authHeaderComponents[1]

            if !jwtComposer.verifySignedToken(signedJWTToken) {
                Log.error("invailid jwt")
                try response.send(json: JSON(["message": "invailid jwt"]))
                            .status(.badRequest).end()
                return
            }

            if !jwtComposer.verifyPayloadForSignedToken(signedJWTToken, verifyPayload: verifyPayload) {
                Log.error("couldn't find iss, exp, and sub in jwt")
                try response.send(json: JSON(["message": "couldn't find issuer, expiration, and subject in jwt"]))
                            .status(.badRequest).end()
                return
            }

        } catch {
            Log.error("failed to decode or validate jwt: \(error)")
        }

        next()
    }

    private func verifyPayload(_ payload: [String: Any]) -> Bool {
        guard let iss = payload["iss"] as? String,
            let exp = payload["exp"] as? Double,
            let sub = payload["sub"] as? String else {
            return false
        }

        Log.info("jwt.payload['iss'] = \(iss)")
        Log.info("jwt.payload['exp'] = \(exp)")
        Log.info("jwt.payload['sub'] = \(sub)")

        return iss == "http://gamenight.udacity.com" &&
            sub == "users microservice"
    }
}
