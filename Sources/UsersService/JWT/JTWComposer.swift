import PerfectCrypto
import LoggerAPI

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

    public func createSignedTokenWithPayload(_ payload: [String:Any]) -> String? {
        guard let privateKey = privateKey else {
            Log.error("private key is null, cannot sign token")
            return nil
        }

        guard let jwt = JWTCreator(payload: payload) else {
            Log.error("could not create jwt with payload")
            return nil
        }

        do {
            let privateKeyAsPem = try PEMKey(source: privateKey)
            return try jwt.sign(alg: .rs256, key: privateKeyAsPem)
        } catch let error as KeyError {
            Log.error("KeyError: \(error.msg)")
            return nil
        } catch JWT.Error.signingError(let message) {
            Log.error("JWT.Error.signingError: \(message)")
            return nil
        } catch {
            Log.error("could not sign jwt with payload: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: Check Token

    /// Verify token based on the indicated algorithm and key.
    public func verifySignedToken(_ token: String) -> Bool {
        guard let publicKey = publicKey else {
            Log.error("public key is null, cannot verify token")
            return false
        }

        guard let jwt = JWTVerifier(token) else {
            Log.error("could not create jwt object to verifty token")
            return false
        }

    	do {
            let publicKeyAsPem = try PEMKey(source: publicKey)
            try jwt.verify(algo: .rs256, key: publicKeyAsPem)
        } catch {
            Log.error("could not verify token: \(error.localizedDescription)")
            return false
        }

        return true
    }

    /// Verify token based on payload.
    public func verifyPayloadForSignedToken(_ token: String, verifyPayload: ([String: Any]) -> Bool) -> Bool {
        guard let jwt = JWTVerifier(token) else {
            Log.error("could not create jwt object to verifty token payload")
            return false
        }

        return verifyPayload(jwt.payload)
    }
}
