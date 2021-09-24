//
//  File.swift
//  File
//
//  Created by lmcmz on 24/9/21.
//

import Foundation

struct AuthnResponse: Decodable {
    public let fType: String
    public let fVsn: String
    public let status: Status
    public var updates: Service?
    public var local: Service?
    public var data: AuthnData?
    public let reason: String?
}

struct AuthnData: Decodable {
    public let addr: String?
    public let fType: String
    public let fVsn: String?
    public let services: [Service]?
    public let proposer: Service?
    public let payer: [Service]?
    public let authorization: [Service]?
    public let signature: String?
}

enum Status: String, Decodable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case declined = "DECLINED"
}

struct Service: Decodable {
    let fType: String?
    let fVsn: String?
    let type: FCLServiceType?
    let method: FCLServiceMethod
    let endpoint: String
    let uid: String?
    let id: String?
    public let identity: Identity?
    public let provider: Provider?
}

struct Identity: Decodable {
    public let address: String
    let keyId: Int
}

struct Provider: Decodable {
    public let fType: String?
    public let fVsn: String?
    public let address: String
    public let name: String
}
