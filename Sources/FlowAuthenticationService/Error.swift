//
//  File.swift
//
//
//  Created by lmcmz on 23/9/21.
//

import Foundation

public enum FlowError: String, Error, LocalizedError {
    case generic
    case urlInvaild
    case declined
    case invalidResponse
    case decodeFailure
    case unauthenticated
    case missingAppInfo
    case missingWalletService

    public var errorDescription: String? {
        return rawValue
    }
}
