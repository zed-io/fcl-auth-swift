//
//  File.swift
//
//
//  Created by lmcmz on 22/9/21.
//

import Foundation

public struct FlowData: Codable {
    public let address: String
    // TODO: Add more object
}

public struct FlowAppData {
    public let title: String
    public let icon: URL

    public init(title: String, icon: URL) {
        self.title = title
        self.icon = icon
    }
}

public struct FlowWalletService: Equatable {
    public let id: String
    public let name: String
    public let method: Method
    public let endpoint: URL
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

struct AuthnResponse: Codable {
    public let fType: String
    public let fVsn: String
    public let status: Status
    public var updates: Service?
    public var local: Service?
    public var data: AuthData?
    public let reason: String?
}

struct AuthData: Codable {
    public let addr: String?
    public let fType: String
    public let fVsn: String?
    public let services: [Service]?
    public let proposer: Service?
    public let payer: [Service]?
    public let authorization: [Service]?
    public let signature: String?
}

enum Status: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case declined = "DECLINED"
}

struct Service: Codable {
    let fType: String?
    let fVsn: String?
    let type: Name?
    let method: Method
    let endpoint: String
    let uid: String?
    let id: String?
    public let identity: Identity?
    public let provider: Provider?
}

public enum Method: String, Codable {
    case post = "HTTP/POST"
    case get = "HTTP/GET"
    case iframe = "VIEW/IFRAME"
}

enum Name: String, Codable {
    case authn
    case authz
    case preAuthz = "pre-authz"
    case userSignature = "user-signature"
    case backChannel = "back-channel-rpc"
}

struct Identity: Codable {
    public let address: String
    let keyId: Int
}

struct Provider: Codable {
    public let fType: String?
    public let fVsn: String?
    public let address: String
    public let name: String
}
