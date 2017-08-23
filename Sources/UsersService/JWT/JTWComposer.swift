import PerfectCrypto

// MARK: - JWTComposer

public class JWTComposer {

    // MARK: Properties

    private let privateKey: String
    private let publicKey: String

    // MARK: Initializer

    public init(privateKey: String, publicKey: String) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }
}
