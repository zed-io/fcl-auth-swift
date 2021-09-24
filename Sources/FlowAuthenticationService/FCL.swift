//
//  File.swift
//
//
//  Created by lmcmz on 23/9/21.
//

import AuthenticationServices
import Foundation

public class FCL: NSObject {
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
}

extension FCL: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = self.delegate?.presentationAnchor() {
            return anchor
        }
        return ASPresentationAnchor()
    }
}
