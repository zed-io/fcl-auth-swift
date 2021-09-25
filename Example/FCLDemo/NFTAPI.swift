//
//  FCLDemo
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

// TODO: replace mock API with real API when available

class NFTAPIClient {
    
    public var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    private func loadJson(url: URL,
                          completion: @escaping (Result<Data, Error>) -> Void) {
        let urlSession = URLSession(configuration: .default).dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            
            if let data = data {
                completion(.success(data))
            }
        }
        
        urlSession.resume()
    }
    
    public func listNFTsForAddress(address: String, completion: @escaping (NFTAPIResponse<NFTList>) -> Void) {
        var fullURL = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
        
        fullURL.queryItems = [
            URLQueryItem(name: "owner", value: address)
        ]
        
        print(fullURL.url!)
        
        self.loadJson(url: fullURL.url!) { (result) in
            switch result {
            case .success(let data):
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
            case .failure(let error):
                print(error)
            }
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
}

struct NFTContract: Decodable, Hashable {
    public let name: String
    public let address: String
}

struct NFTMetaData: Decodable, Hashable {
    public let title: String
    public let image: URL
    public let topShotImages: TopShotImages
    public let topShotPlay: TopShotPlay
    public let createdAt: Date

    public struct TopShotImages: Decodable, Hashable {
        public let assetPathPrefix: URL
        public let hero: URL
        public let black: URL
    }
    
    public struct TopShotPlay: Decodable, Hashable {
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
}
