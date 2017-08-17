import Foundation
import LoggerAPI

public typealias HTTPResult = (Data?, Error?) -> Void

// MARK: - AccountKitClientError: Error

enum AccountKitClientError: Error {
    case networkError
    case customError(String)
}

// https://developers.facebook.com/docs/accountkit/graphapi
// see "Retrieving User Access Tokens with an Authorization Code"

// MARK: - AccountKitClient

public class AccountKitClient {

    // MARK: Properties

    private let session: URLSessionProtocol
    private let appID: String
    private let appSecret: String

    // MARK: Initializer

    init(session: URLSessionProtocol, appID: String, appSecret: String) {
        self.session = session
        self.appID = appID
        self.appSecret = appSecret
    }

    // MARK: Requests

    // exchange user auth code for user access token
    public func getAccessToken(withAuthCode: String, completion: @escaping HTTPResult) {

        // TODO: Use URLComponents

        let urlString = "https://graph.accountkit.com/v1.2/access_token?" +
            "grant_type=authorization_code&" +
            "code=\(withAuthCode)&" +
            "access_token=AA|\(appID)|\(appSecret)"
        
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: encodedString) else {
            print("cannot create url")
            return
        }

        print(url)

        let task = session.dataTaskWithURL(url) { (data, response, error) in
            if let _ = error {
                completion(nil, AccountKitClientError.networkError)
            } else if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                completion(data, nil)
            } else {
                completion(nil, AccountKitClientError.networkError)
            }
        }
        task.resume()
    }

    public func getAccountData(completion: @escaping HTTPResult) {

    }
}
