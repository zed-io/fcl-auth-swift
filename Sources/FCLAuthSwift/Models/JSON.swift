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
    let fType: String
    let fVsn: String
    let status: Status
    var updates: Service?
    var local: Service?
    var data: AuthnData?
    let reason: String?
}

struct AuthnData: Decodable {
    let addr: String?
    let fType: String?
    let fVsn: String?
    let services: [Service]?
    let proposer: Service?
    let payer: [Service]?
    let authorization: [Service]?
    let signature: String?
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
    let method: FCLServiceMethod?
    let endpoint: URL?
    let uid: String?
    let id: String?
    let identity: Identity?
    let provider: Provider?
    let params: [String: String]?

    enum CodingKeys: String, CodingKey {
        case fType
        case fVsn
        case type
        case method
        case endpoint
        case uid
        case id
        case identity
        case provider
        case params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try? container.decode([String: ParamValue].self, forKey: .params)
        var result = [String: String]()
        rawValue?.compactMap { $0 }.forEach { key, value in
            result[key] = value.value
        }
        params = result
        fType = try? container.decode(String.self, forKey: .fType)
        fVsn = try? container.decode(String.self, forKey: .fVsn)
        type = try? container.decode(FCLServiceType.self, forKey: .type)
        method = try? container.decode(FCLServiceMethod.self, forKey: .method)
        endpoint = try? container.decode(URL.self, forKey: .endpoint)
        uid = try? container.decode(String.self, forKey: .uid)
        id = try? container.decode(String.self, forKey: .id)
        identity = try? container.decode(Identity.self, forKey: .identity)
        provider = try? container.decode(Provider.self, forKey: .provider)
    }
}

struct Identity: Decodable {
    let address: String
    let keyId: Int?
}

struct Provider: Decodable {
    let fType: String?
    let fVsn: String?
    let address: String
    let name: String
}

struct ParamValue: Decodable {
    var value: String

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let intVal = try? container.decode(Int.self) {
                value = String(intVal)
            } else if let doubleVal = try? container.decode(Double.self) {
                value = String(doubleVal)
            } else if let boolVal = try? container.decode(Bool.self) {
                value = String(boolVal)
            } else if let stringVal = try? container.decode(String.self) {
                value = stringVal
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "the container contains nothing serialisable")
            }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not serialise"))
        }
    }
}
