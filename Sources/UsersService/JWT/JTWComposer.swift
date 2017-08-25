import Kitura
import LoggerAPI
import Foundation
import PerfectCrypto

// MARK: - JWTError

public enum JWTError: Error {
    case missingPrivateKey
    case missingPublicKey
    case cannotCreateJWT
    case cannotSignJWT(String)
    case cannotVerifyAlgAndKey
    case invalidPayload(String)
}

// MARK: - JWTComposer

public class JWTComposer {

    // MARK: Properties

    private let privateKey: String?
    private let publicKey: String?

    // MARK: Initializer

    public init(privateKey: String?, publicKey: String?) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    // MARK: Create Token

    public func createSignedTokenWithPayload(_ payload: [String:Any]) throws -> String {
        guard let privateKey = privateKey else {
            throw JWTError.missingPrivateKey
        }

        guard let jwt = JWTCreator(payload: payload) else {
            throw JWTError.cannotCreateJWT
        }

        do {
            let privateKeyAsPem = try PEMKey(source: privateKey)
            let signedToken = try jwt.sign(alg: .rs256, key: privateKeyAsPem)
            return signedToken
        } catch is KeyError {
            throw JWTError.cannotCreateJWT
        } catch JWT.Error.signingError(let message) {
            throw JWTError.cannotSignJWT(message)
        } catch {
            throw JWTError.cannotSignJWT(error.localizedDescription)
        }
    }

    // MARK: Check Token

    /// Verify token algorithm and key.
    public func getVerifiedJWTFromSignedToken(_ signedToken: String) throws -> JWTVerifier {
        guard let publicKey = publicKey else {
            throw JWTError.missingPublicKey
        }

        guard let jwt = JWTVerifier(signedToken) else {
            throw JWTError.cannotCreateJWT
        }

    	do {
            let publicKeyAsPem = try PEMKey(source: publicKey)
            try jwt.verify(algo: .rs256, key: publicKeyAsPem)
            return jwt
        } catch {
            throw JWTError.cannotVerifyAlgAndKey
        }
    }

    /// Verify reserved claims.
    public func verifyReservedClaimsForPayload(_ payload: [String: Any], iss issuer: String, sub subject: String) throws {
        guard let payloadIssuer = payload["iss"] as? String,
            let payloadExpiration = payload["exp"] as? Double,
            let payloadSubject = payload["sub"] as? String else {
            throw JWTError.invalidPayload("jwt payload does not contain iss, exp, and sub claims")
        }

        if payloadIssuer != issuer {
            throw JWTError.invalidPayload("jwt iss claim is invalid")
        }

        if payloadSubject != subject {
            throw JWTError.invalidPayload("jwt sub claim is invalid")
        }

        if payloadExpiration < Date().timeIntervalSince1970 {
            throw JWTError.invalidPayload("jwt has expired")
        }
    }

    /// Verify private claims.
    public func verifyPrivateClaimsForPayload(_ payload: [String: Any], verifyPrivateClaims: ([String: Any]) -> [String]) throws {
        let invalidClaims = verifyPrivateClaims(payload)
        if invalidClaims.count > 0 {
            throw JWTError.invalidPayload("jwt private claims are invalid: \(invalidClaims)")
        }
    }
}
