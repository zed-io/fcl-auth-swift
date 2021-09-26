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

public enum FCLProvider: Equatable {
    case dapper
    case blocto
    case custom(FCLWalletProvider)

    var provider: FCLWalletProvider {
        switch self {
        case .dapper:
            return FCLWalletProvider(id: "dapper",
                                     name: "Dapper",
                                     method: .httpPost,
                                     endpoint: URL(string: "https://dapper-http-post.vercel.app/api/authn")!)
        case .blocto:
            return FCLWalletProvider(id: "blocto",
                                     name: "Blocto",
                                     method: .httpPost,
                                     endpoint: URL(string: "https://flow-wallet.blocto.app/api/flow/authn")!)
        case let .custom(provider):
            return provider
        }
    }

    public static func == (lhs: FCLProvider, rhs: FCLProvider) -> Bool {
        return lhs.provider == rhs.provider
    }
}

public struct FCLWalletProvider: Equatable {
    public let id: String
    public let name: String
    public let method: FCLServiceMethod
    public let endpoint: URL

    public init(id: String, name: String, method: FCLServiceMethod, endpoint: URL) {
        self.id = id
        self.name = name
        self.method = method
        self.endpoint = endpoint
    }
}
