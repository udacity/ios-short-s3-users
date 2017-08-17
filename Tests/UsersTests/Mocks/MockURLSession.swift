//
//  URLSessionProtocol.swift
//  TestingNSURLSession
//
//  Created by Joe Masilotti on 1/8/16.
//  Copyright © 2016 Masilotti.com. All rights reserved.
//
//  UPDATED by Jarrod Parkes on 08/17/17.
//

import Foundation
import UsersService

// MARK: - MockURLSession: URLSessionProtocol

class MockURLSession: URLSessionProtocol {

    // MARK: Properties

    public var lastURL: URL?
    public var nextDataTask = MockURLSessionDataTask()
    public var nextData: Data?
    public var nextResponse: URLResponse?
    public var nextError: Error?

    // MARK: Mock Data Task

    func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastURL = url
        completionHandler(nextData, nextResponse, nextError)
        return nextDataTask
    }
}
