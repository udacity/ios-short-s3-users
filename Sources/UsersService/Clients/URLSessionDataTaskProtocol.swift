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

// MARK: - URLSessionDataTaskProtocol

public protocol URLSessionDataTaskProtocol {
    func resume()
}

// MARK: - URLSessionDataTask: URLSessionDataTaskProtocol

extension URLSessionDataTask: URLSessionDataTaskProtocol { }
