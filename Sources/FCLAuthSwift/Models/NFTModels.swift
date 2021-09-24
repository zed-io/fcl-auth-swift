//
//  File.swift
//  File
//
//  Created by lmcmz on 24/9/21.
//

import Foundation

public struct NFTResponse: Decodable {
    public let owner: String
    public let nfts: [NFTModel]
}

public struct NFTModel: Decodable {
    public let id: String
    public let contract: Contract
    public let metadata: MetaData
}

public struct Contract: Decodable {
    public let name: String
    public let address: String
}

public struct MetaData: Decodable {
    public let image: Image
    public let play: Play
    public let createdAt: Date

    public struct Play: Decodable {
        public let id: String
        public let description: String
        public let stats: Stats

        public struct Stats: Decodable {
            public let playerName: String
            public let jerseyNumber: String
            public let totalYearsExperience: String
            public let teamAtMoment: String
        }
    }

    public struct Image: Decodable {
        public let assetPathPrefix: String
        public let hero: String
        public let black: String
    }
}
