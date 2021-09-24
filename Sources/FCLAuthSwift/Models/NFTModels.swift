//
//  File.swift
//  File
//
//  Created by lmcmz on 24/9/21.
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
