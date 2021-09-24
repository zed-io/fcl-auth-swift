//
//  File.swift
//
//
//  Created by lmcmz on 22/9/21.
//

import Foundation

public struct FCLApplication {
    public let title: String
    public let icon: URL

    public init(title: String, icon: URL) {
        self.title = title
        self.icon = icon
    }
}

public enum FCLServiceMethod: String, Decodable {
    case httpPost = "HTTP/POST"
    case httpGet = "HTTP/GET"
    case iframe = "VIEW/IFRAME"
}

public enum FCLServiceType: String, Decodable {
    case authn
    case authz
    case preAuthz = "pre-authz"
    case userSignature = "user-signature"
    case backChannel = "back-channel-rpc"
}


public enum FCLResponse<T: Decodable> {
    case failure(error: Error)
    case success(result: T)

    public func whenSuccess(completion: @escaping (T) -> Void) {
        if case let .success(result) = self {
            completion(result)
        }
    }

    public func whenFailure(completion: @escaping (Error) -> Void) {
        if case let .failure(error) = self {
            completion(error)
        }
    }
}

public struct FCLAuthnResponse: Decodable {
    public let address: String
    // TODO: add additional fields
}
