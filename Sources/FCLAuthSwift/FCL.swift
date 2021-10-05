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

public let fcl = FCL.shared

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

    public func authenticate(providerID: String, completion: @escaping (Result<FCLAuthnResponse, Error>) -> Void) {
        guard let provider = providers.filter({ $0.provider.id == providerID }).first else {
            completion(Result.failure(FCLError.missingWalletService))
            return
        }
        authenticate(provider: provider, completion: completion)
    }

    public func authenticate(provider: FCLProvider = .dapper, completion: @escaping (Result<FCLAuthnResponse, Error>) -> Void) {
        guard let _ = appInfo else {
            completion(Result.failure(FCLError.missingAppInfo))
            return
        }

        guard providers.contains(provider) else {
            completion(Result.failure(FCLError.missingWalletService))
            return
        }

        execHTTPPost(url: provider.provider.endpoint) { response in
            switch response {
            case let .success(result):
                guard let address = result.data?.addr else {
                    completion(Result.failure(FCLError.invalidResponse))
                    return
                }
                let result = FCLAuthnResponse(address: address)
                completion(Result.success(result))
            case let .failure(error):
                completion(Result.failure(error))
            }
        }
    }

    private func fetchService(url: URL,
                              method: String,
                              params: [String: String]? = [:],
                              completion: @escaping (Result<AuthnResponse, Error>) -> Void) {
        guard let fullURL = self.buildURL(url: url, params: params) else {
            completion(Result.failure(FCLError.invaildURL))
            return
        }

        var request = URLRequest(url: fullURL)
        request.httpMethod = method

        // TODO: Need to check extract config
        let config = URLSessionConfiguration.default
        let task = URLSession(configuration: config).dataTask(with: request) { data, response, error in

            if let error = error {
                completion(Result.failure(error))
                return
            }

            guard let data = data else {
                completion(Result.failure(FCLError.invalidResponse))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(AuthnResponse.self, from: data)
                completion(Result.success(response))
            } catch {
                completion(Result.failure(error))
            }
        }
        task.resume()
    }

    private func execHTTPPost(url: URL, completion: @escaping (Result<AuthnResponse, Error>) -> Void) {
        DispatchQueue.main.async {
            self.delegate?.showLoading()
        }

        fetchService(url: url, method: "POST") { response in

            DispatchQueue.main.async {
                self.delegate?.hideLoading()
            }

            switch response {
            case let .success(result):
                switch result.status {
                case .approved:
                    completion(response)
                case .declined:
                    completion(Result.failure(FCLError.declined))
                case .pending:
                    self.canContinue = true
                    guard let local = result.local, let updates = result.updates else {
                        completion(Result.failure(FCLError.generic))
                        return
                    }
                    do {
                        try self.openAuthenticationSession(service: local)
                    } catch {
                        completion(Result.failure(error))
                    }
                    self.poll(service: updates) { response in
                        completion(response)
                    }
                }
            case let .failure(error):
                completion(Result.failure(error))
            }
        }
    }

    private func poll(service: Service, completion: @escaping (Result<AuthnResponse, Error>) -> Void) {
        if !canContinue {
            completion(Result.failure(FCLError.declined))
            return
        }

        guard let url = service.endpoint else {
            completion(Result.failure(FCLError.invaildURL))
            return
        }

        fetchService(url: url, method: "GET", params: service.params) { response in
            if case let .success(result) = response {
                switch result.status {
                case .approved:
                    self.closeSession()
                    completion(response)
                case .declined:
                    completion(Result.failure(FCLError.declined))
                case .pending:
                    // TODO: Improve this
                    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.poll(service: service) { response in
                            completion(response)
                        }
                    }
                }
            }

            if case let .failure(error) = response {
                completion(Result.failure(error))
            }
        }
    }

    // MARK: - Session

    private func openAuthenticationSession(service: Service) throws {
        guard let endpoint = service.endpoint,
            let url = self.buildURL(url: endpoint, params: service.params) else {
            throw FCLError.invalidSession
        }

        DispatchQueue.main.async {
            let session = ASWebAuthenticationSession(url: url,
                                                     callbackURLScheme: nil) { _, _ in
                self.canContinue = false
            }
            self.session = session
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func buildURL(url: URL, params: [String: String]?) -> URL? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var queryItems: [URLQueryItem] = []

        if let location = self.appInfo?.location.absoluteString {
            queryItems.append(URLQueryItem(name: paramLocation, value: location))
        }

        for (name, value) in params ?? [:] {
            if name != paramLocation {
                queryItems.append(
                    URLQueryItem(name: name, value: value)
                )
            }
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
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
