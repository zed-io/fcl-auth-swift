//
//  File.swift
//  File
//
//  Created by lmcmz on 24/9/21.
//

import Foundation

public struct FlowWalletService: Equatable {
    public let id: String
    public let name: String
    public let method: Method
    public let endpoint: URL

    public init(id: String, name: String, method: Method, endpoint: URL) {
        self.id = id
        self.name = name
        self.method = method
        self.endpoint = endpoint
    }
}

public enum FlowWalletProvider: Equatable {
    case dapper
    case blocto
    case custom(FlowWalletService)

    var service: FlowWalletService {
        switch self {
        case .dapper:
            return FlowWalletService(id: "dapper",
                                     name: "Dapper",
                                     method: .post,
                                     endpoint: URL(string: "https://dapper-http-post.vercel.app/api/")!)
        case .blocto:
            return FlowWalletService(id: "blocto",
                                     name: "Blocto",
                                     method: .post,
                                     endpoint: URL(string: "https://dapper-http-post.vercel.app/api/")!)
        case let .custom(service):
            return service
        }
    }

    public static func == (lhs: FlowWalletProvider, rhs: FlowWalletProvider) -> Bool {
        return lhs.service == rhs.service
    }
}
