//
//  URLSessionProtocol.swift
//  TestingNSURLSession
//
//  Created by Joe Masilotti on 1/8/16.
//  Copyright © 2016 Masilotti.com. All rights reserved.
//
//  UPDATED by Jarrod Parkes on 08/17/17.
//

import UsersService

// MARK: - MockURLSessionDataTask: URLSessionDataTaskProtocol

class MockURLSessionDataTask: URLSessionDataTaskProtocol {

    // MARK: Properties

    private var resumeWasCalled = false

    // MARK: Mock Resume

    func resume() {
        resumeWasCalled = true
    }
}
