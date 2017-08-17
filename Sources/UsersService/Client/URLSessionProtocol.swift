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

// MARK: - DataTaskResult

public typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

// MARK: - URLSessionProtocol

public protocol URLSessionProtocol {
    func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}
