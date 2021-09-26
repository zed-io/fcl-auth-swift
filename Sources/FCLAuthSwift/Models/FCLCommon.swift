//
//  FCLAuthSwift
//
//  Copyright 2021 Zed Labs Pty Ltd
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public struct FCLAppInfo {
    public let title: String
    public let icon: URL
    public let location: URL

    public init(title: String, icon: URL, location: URL) {
        self.title = title
        self.icon = icon
        self.location = location
    }
}

public enum FCLServiceMethod: String, Decodable {
    case httpPost = "HTTP/POST"
    case httpGet = "HTTP/GET"
    case iframe = "VIEW/IFRAME"
    case iframeRPC = "IFRAME/RPC"
    case data = "DATA"
}

public enum FCLServiceType: String, Decodable {
    case authn
    case authz
    case preAuthz = "pre-authz"
    case userSignature = "user-signature"
    case backChannel = "back-channel-rpc"
    case localView = "local-view"
    case openID = "open-id"
}

public let paramLocation = "l6n"

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
