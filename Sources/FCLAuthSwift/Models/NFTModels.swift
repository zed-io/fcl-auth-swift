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

public struct NFTResponse: Decodable, Hashable {
    public let owner: String
    public let nfts: [NFTModel]
}

public struct NFTModel: Decodable, Hashable {
    public let id: String
    public let contract: Contract
    public let metadata: MetaData

    public static func == (lhs: NFTModel, rhs: NFTModel) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Contract: Decodable, Hashable {
    public let name: String
    public let address: String
}

public struct MetaData: Decodable, Hashable {
    public let image: Image
    public let play: Play
    public let createdAt: Date

    public struct Play: Decodable, Hashable {
        public let id: String
        public let description: String
        public let stats: Stats

        public struct Stats: Decodable, Hashable {
            public let playerName: String
            public let jerseyNumber: String
            public let totalYearsExperience: String
            public let teamAtMoment: String
        }
    }

    public struct Image: Decodable, Hashable {
        public let assetPathPrefix: URL
        public let hero: URL
        public let black: URL
    }
}
