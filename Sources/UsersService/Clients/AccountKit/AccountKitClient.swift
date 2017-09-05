// https://developers.facebook.com/docs/accountkit/graphapi

import Foundation
import LoggerAPI

// MARK: - AccountKitClientError: Error

enum AccountKitClientError: Error {
    case networkError(String)
    case customError(String)
}

// MARK: - AccountKitClient

public class AccountKitClient {

    // MARK: Properties

    private let session: URLSessionProtocol
    private let appID: String
    private let appSecret: String

    // MARK: Initializer

    public init(session: URLSessionProtocol, appID: String, appSecret: String) {
        self.session = session
        self.appID = appID
        self.appSecret = appSecret
    }

    // MARK: Requests

    public func getAccessToken(withAuthCode: String, completion: @escaping (Data?, Error?) throws -> Void) {

        // Exchange user auth code for user access token
        guard let url = getURLWithPath("/access_token", withParameters: [
            "grant_type": "authorization_code",
            "code": withAuthCode,
            "access_token": "AA|\(appID)|\(appSecret)"
        ]) else {
            Log.error("Could not create url for getAccessToken")
            return
        }

        let task = session.dataTaskWithURL(url) { (data, response, error) in
            do {
                if let data = data {
                    try completion(data, nil)
                } else if let error = error {
                    try completion(nil, AccountKitClientError.networkError(error.localizedDescription))
                } else {
                    try completion(nil, AccountKitClientError.customError("Unknown error"))
                }
            } catch {
                Log.error("Unable to parse response for getAccessToken \(error.localizedDescription)")
                return
            }
        }
        task.resume()
    }

    // MARK: Utility

    private func getURLWithPath(_ path: String, withParameters parameters: [String:Any]) -> URL? {

        var components = URLComponents()
        components.scheme = "https"
        components.host = "graph.accountkit.com"
        components.path = "/v1.2" + path
        components.queryItems = [URLQueryItem]()

        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }

        return components.url
    }
}
