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

// MARK: - URLSession: URLSessionProtocol

extension URLSession: URLSessionProtocol {
    public func dataTaskWithURL(_ url: URL, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: url, completionHandler: completionHandler)) as URLSessionDataTaskProtocol
    }
}
