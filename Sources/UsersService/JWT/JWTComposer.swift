import Kitura
import LoggerAPI
import Foundation
import PerfectCrypto

// MARK: - JWTError

public enum JWTError: Error {
    case missingPrivateKey
    case missingPublicKey
    case cannotCreateJWT(String)
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
            throw JWTError.cannotCreateJWT("Cannot initialize JWTCreator.")
        }

        do {
            let privateKeyAsPem = try PEMKey(source: privateKey)
            let signedToken = try jwt.sign(alg: .rs256, key: privateKeyAsPem)
            return signedToken
        } catch let error as KeyError {
            throw JWTError.cannotCreateJWT(error.msg)
        } catch JWT.Error.signingError(let message) {
            throw JWTError.cannotSignJWT(message)
        } catch {
            throw JWTError.cannotSignJWT(error.localizedDescription)
        }
    }

    // MARK: Get Verifier

    public func getJWTVerifierWithSignedToken(_ signedToken: String) throws -> JWTVerifier {
        guard let jwtVerifier = JWTVerifier(signedToken) else {
            throw JWTError.cannotCreateJWT("Cannot initialize JWTVerifier.")
        }

        return jwtVerifier
    }

    // MARK: Check Token

    public func verifyAlgorithmAndKeyForJWT(_ jwt: JWTVerifier) throws {
        guard let publicKey = publicKey else {
            throw JWTError.missingPublicKey
        }

    	do {
            let publicKeyAsPem = try PEMKey(source: publicKey)
            try jwt.verify(algo: .rs256, key: publicKeyAsPem)
        } catch {
            throw JWTError.cannotVerifyAlgAndKey
        }
    }

    public func verifyReservedClaimsForJWT(_ jwt: JWTVerifier, iss issuer: String, sub subject: String) throws {
        guard let payloadIssuer = jwt.payload["iss"] as? String,
            let payloadExpiration = jwt.payload["exp"] as? Double,
            let payloadSubject = jwt.payload["sub"] as? String else {
            throw JWTError.invalidPayload("JWT payload invalid claims: iss, exp, and sub claims")
        }

        if payloadIssuer != issuer {
            throw JWTError.invalidPayload("JWT iss claim is invalid")
        }

        if payloadSubject != subject {
            throw JWTError.invalidPayload("JWT sub claim is invalid")
        }

        if payloadExpiration < Date().timeIntervalSince1970 {
            throw JWTError.invalidPayload("JWT has expired")
        }
    }

    public func invalidPrivateClaimsForJWT(_ jwt: JWTVerifier, verifyPrivateClaims: ([String: Any]) -> [String]) throws {
        let invalidClaims = verifyPrivateClaims(jwt.payload)
        if invalidClaims.count > 0 {
            throw JWTError.invalidPayload("JWT private claims are invalid: \(invalidClaims)")
        }
    }
}
