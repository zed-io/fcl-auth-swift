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
    public var delegate: FCLAuthDelegate?
    private var canContinue = true
    private var session: ASWebAuthenticationSession?
    private var appInfo: FCLAppInfo?
    private var providers: [FCLProvider] = [.dapper, .blocto]

    public func config(
        appInfo: FCLAppInfo,
        providers: [FCLProvider] = [.dapper, .blocto]
    ) {
        self.appInfo = appInfo
        self.providers = providers
    }

    // MARK: - Authenticate

    public func authenticate(providerID: String, completion: @escaping (FCLResponse<FCLAuthnResponse>) -> Void) {
        guard let provider = providers.filter({ $0.provider.id == providerID }).first else {
            completion(FCLResponse.failure(error: FCLError.missingWalletService))
            return
        }
        authenticate(provider: provider, completion: completion)
    }

    public func authenticate(provider: FCLProvider = .dapper, completion: @escaping (FCLResponse<FCLAuthnResponse>) -> Void) {
        guard let _ = appInfo else {
            completion(FCLResponse.failure(error: FCLError.missingAppInfo))
            return
        }

        guard providers.contains(provider) else {
            completion(FCLResponse.failure(error: FCLError.missingWalletService))
            return
        }

        execHTTPPost(url: provider.provider.endpoint) { response in
            response.whenSuccess { result in
                guard let address = result.data?.addr else {
                    completion(FCLResponse.failure(error: FCLError.invalidResponse))
                    return
                }
                let result = FCLAuthnResponse(address: address)
                completion(FCLResponse.success(result: result))
            }

            response.whenFailure { error in
                completion(FCLResponse.failure(error: error))
            }
        }
    }

    private func fetchService(url: URL,
                              method: String,
                              params: [String: String] = [:],
                              completion: @escaping (FCLResponse<AuthnResponse>) -> Void) {
        
        let fullURL = self.buildURL(url: url, params: params)
                        
        var request = URLRequest(url: fullURL)
        request.httpMethod = method

        // TODO: Need to check extract config
        let config = URLSessionConfiguration.default
        let task = URLSession(configuration: config).dataTask(with: request) { data, response, error in
            
            if let error = error {
                completion(FCLResponse.failure(error: error))
                return
            }

            guard let data = data else {
                completion(FCLResponse.failure(error: FCLError.invalidResponse))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(AuthnResponse.self, from: data)
                completion(FCLResponse.success(result: response))
            } catch {
                completion(FCLResponse.failure(error: error))
            }
        }
        task.resume()
    }

    private func execHTTPPost(url: URL, completion: @escaping (FCLResponse<AuthnResponse>) -> Void) {
        DispatchQueue.main.async {
            self.delegate?.showLoading()
        }
        
        fetchService(url: url, method: "POST") { response in
            response.whenSuccess { result in
                switch result.status {
                case .approved:
                    completion(response)
                case .declined:
                    completion(FCLResponse.failure(error: FCLError.declined))
                case .pending:
                    self.canContinue = true
                    guard let local = result.local, let updates = result.updates else {
                        completion(FCLResponse.failure(error: FCLError.generic))
                        return
                    }
                    self.openAuthenticationSession(service: local)
                    self.poll(service: updates) { response in
                        completion(response)
                    }
                }
            }

            response.whenFailure { error in
                completion(FCLResponse.failure(error: error))
            }
        }
    }

    private func poll(service: Service, completion: @escaping (FCLResponse<AuthnResponse>) -> Void) {
        if !canContinue {
            completion(FCLResponse.failure(error: FCLError.declined))
            return
        }

        guard let url = service.endpoint else {
            completion(FCLResponse.failure(error: FCLError.urlInvaild))
            return
        }

        fetchService(url: url, method: "GET", params: service.params!) { response in
            response.whenSuccess { result in
                switch result.status {
                case .approved:
                    self.closeSession()
                    completion(response)
                case .declined:
                    completion(FCLResponse.failure(error: FCLError.declined))
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

    private func openAuthenticationSession(service: Service) {
        let url = self.buildURL(url: service.endpoint!, params: service.params!)
                
        DispatchQueue.main.async {
            self.delegate?.hideLoading()
            let session = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: nil) { _, _ in
                self.canContinue = false
            }
            self.session = session
            session.presentationContextProvider = self
            // TODO: Need to check this
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }
    
    private func buildURL(url: URL, params: [String: String]) -> URL {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        var queryItems = [
            URLQueryItem(name: paramLocation, value: self.appInfo!.location.absoluteString)
        ]
        
        for (name, value) in params {
            if (name != paramLocation) {
                queryItems.append(
                    URLQueryItem(name: name, value: value)
                )
            }
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.url!
    }

    private func closeSession() {
        DispatchQueue.main.async {
            self.session?.cancel()
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
