import XCTest

@testable import UsersService
@testable import MySQL

// MARK: - AccountKitClientTests: XCTestCase
class AccountKitClientTests: XCTestCase {

    // MARK: Properties

    var session = MockURLSession()
    var client: AccountKitClient!

    // MARK: Setup

    public override func setUp() {
        super.setUp()
        client = AccountKitClient(session: session, appID: "app-id", appSecret: "app-secret")
    }

    // MARK: Tests

    func testGetUserAccessTokenRequestsURL() throws {
        client.getAccessToken(withAuthCode: "") { (_, _) -> Void in }

        XCTAssertNotNil(session.lastURL)
    }
}

#if os(Linux)
extension AccountKitClientTests {
    static var allTests: [(String, (AccountKitClientTests) -> () throws -> Void)] {
        return [
            ("testGetUserAccessTokenRequestsURL", testGetUserAccessTokenRequestsURL)
        ]
    }
}
#endif
