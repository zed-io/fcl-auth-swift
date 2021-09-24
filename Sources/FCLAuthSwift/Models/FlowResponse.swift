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

struct AuthnResponse: Decodable {
    public let fType: String
    public let fVsn: String
    public let status: Status
    public var updates: Service?
    public var local: Service?
    public var data: AuthData?
    public let reason: String?
}

struct AuthData: Decodable {
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
    let type: Name?
    let method: Method
    let endpoint: String
    let uid: String?
    let id: String?
    public let identity: Identity?
    public let provider: Provider?
}

public enum Method: String, Decodable {
    case post = "HTTP/POST"
    case get = "HTTP/GET"
    case iframe = "VIEW/IFRAME"
}

enum Name: String, Decodable {
    case authn
    case authz
    case preAuthz = "pre-authz"
    case userSignature = "user-signature"
    case backChannel = "back-channel-rpc"
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
