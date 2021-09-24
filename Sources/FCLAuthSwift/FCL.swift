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

import AuthenticationServices
import Foundation

public final class FCL: NSObject {
    public static let shared = FCL()
    public var delegate: FlowAuthDelegate?
    private var canContinue = true
    private var session: ASWebAuthenticationSession?
    private var appData: FlowAppData?
    private var walletProviders: [FlowWalletProvider] = [.dapper, .blocto]

    public func config(app: FlowAppData, providers: [FlowWalletProvider] = [.dapper, .blocto]) {
        appData = app
        walletProviders = providers
    }

    // MARK: - Authenticate

    public func authenticate(providerID: String, completion: @escaping (FlowResponse<FlowData>) -> Void) {
        guard let provider = walletProviders.filter({ $0.service.id == providerID }).first else {
            completion(FlowResponse.failure(error: FlowError.missingWalletService))
            return
        }
        authenticate(provider: provider, completion: completion)
    }

    public func authenticate(provider: FlowWalletProvider = .dapper, completion: @escaping (FlowResponse<FlowData>) -> Void) {
        guard let _ = appData else {
            completion(FlowResponse.failure(error: FlowError.missingAppInfo))
            return
        }

        guard walletProviders.contains(provider) else {
            completion(FlowResponse.failure(error: FlowError.missingWalletService))
            return
        }

        let url = URL(string: "https://dapper-http-post.vercel.app/api/authn")!
        execHttpPost(url: url) { response in
            response.whenSuccess { result in
                guard let address = result.data?.addr else {
                    completion(FlowResponse.failure(error: FlowError.invalidResponse))
                    return
                }
                let result = FlowData(address: address)
                completion(FlowResponse.success(result: result))
            }

            response.whenFailure { error in
                completion(FlowResponse.failure(error: error))
            }
        }
    }

    private func fetchService(url: URL, completion: @escaping (FlowResponse<AuthnResponse>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // TODO: Need to check extract config
        let config = URLSessionConfiguration.default
        let task = URLSession(configuration: config).dataTask(with: request) { data, response, error in

            if let error = error {
                completion(FlowResponse.failure(error: error))
                return
            }

            guard let data = data else {
                completion(FlowResponse.failure(error: FlowError.invalidResponse))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(AuthnResponse.self, from: data)
                completion(FlowResponse.success(result: response))
            } catch {
                completion(FlowResponse.failure(error: error))
            }
        }
        task.resume()
    }

    private func execHttpPost(url: URL, completion: @escaping (FlowResponse<AuthnResponse>) -> Void) {
        DispatchQueue.main.async {
            self.delegate?.showLoading()
        }
        fetchService(url: url) { response in
            response.whenSuccess { result in
                switch result.status {
                case .approved:
                    completion(response)
                case .declined:
                    completion(FlowResponse.failure(error: FlowError.declined))
                case .pending:
                    self.canContinue = true
                    guard let local = result.local, let updates = result.updates else {
                        completion(FlowResponse.failure(error: FlowError.generic))
                        return
                    }
                    guard let url = URL(string: local.endpoint) else {
                        completion(FlowResponse.failure(error: FlowError.urlInvaild))
                        return
                    }
                    self.openAuthenticationSession(url: url)
                    self.poll(service: updates) { response in
                        completion(response)
                    }
                }
            }

            response.whenFailure { error in
                completion(FlowResponse.failure(error: error))
            }
        }
    }

    private func poll(service: Service, completion: @escaping (FlowResponse<AuthnResponse>) -> Void) {
        if !canContinue {
            completion(FlowResponse.failure(error: FlowError.declined))
            return
        }

        guard let url = URL(string: service.endpoint) else {
            completion(FlowResponse.failure(error: FlowError.urlInvaild))
            return
        }

        fetchService(url: url) { response in
            response.whenSuccess { result in
                print("polling ---> \(result.status.rawValue)")
                switch result.status {
                case .approved:
                    self.closeSession()
                    completion(response)
                case .declined:
                    completion(FlowResponse.failure(error: FlowError.declined))
                case .pending:
                    // TODO: Improve this
                    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.poll(service: service) { response in
                            completion(response)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Session

    private func openAuthenticationSession(url: URL) {
        DispatchQueue.main.async {
            self.delegate?.hideLoading()
            let session = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: "fclDemo") { _, _ in
                self.canContinue = false
            }
            self.session = session
            session.presentationContextProvider = self
            // TODO: Need to check this
//            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    private func closeSession() {
        DispatchQueue.main.async {
            self.session?.cancel()
        }
    }

    // MARK: - NFTs

    // TODO: It is a mock func for now, just for demo purpose
    // Will update this when API is available
    public func fetchNFTs(address _: String, completion: @escaping (FlowResponse<NFTResponse>) -> Void) {
        guard let url = Bundle.module.url(forResource: "nft-mock", withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
            completion(FlowResponse.failure(error: FlowError.generic))
            return
        }

        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let response = try decoder.decode(NFTResponse.self, from: data)
            completion(FlowResponse.success(result: response))
        } catch {
            completion(FlowResponse.failure(error: FlowError.invalidResponse))
        }
    }
}

extension FCL: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = self.delegate?.presentationAnchor() {
            return anchor
        }
        return ASPresentationAnchor()
    }
}
