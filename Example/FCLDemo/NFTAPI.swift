//
//  NFTAPI.swift
//  
//
//  Created by Peter Siemens on 2021-09-24.
//

import Foundation

// TODO: replace mock data with real API when available

class NFTAPIClient {
    public func listNFTsForAddress(address _: String, completion: @escaping (NFTAPIResponse<NFTList>) -> Void) {
        guard let url = Bundle.main.url(forResource: "nft-api-mock", withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
            completion(NFTAPIResponse.failure(error: NFTAPIError.generic))
            return
        }

        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let response = try decoder.decode(NFTList.self, from: data)
            completion(NFTAPIResponse.success(result: response))
        } catch {
            completion(NFTAPIResponse.failure(error: NFTAPIError.invalidResponse))
        }
    }
}

enum NFTAPIResponse<T: Decodable> {
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

enum NFTAPIError: String, Error, LocalizedError {
    case generic
    case invalidResponse

    public var errorDescription: String? {
        return rawValue
    }
}

struct NFTList: Decodable, Hashable {
    public let owner: String
    public let nfts: [NFT]
}

struct NFT: Decodable, Hashable {
    public let id: String
    public let contract: NFTContract
    public let metadata: NFTMetaData

    public static func == (lhs: NFT, rhs: NFT) -> Bool {
        return lhs.id == rhs.id
    }
}

struct NFTContract: Decodable, Hashable {
    public let name: String
    public let address: String
}

struct NFTMetaData: Decodable, Hashable {
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
