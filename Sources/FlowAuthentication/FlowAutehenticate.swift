//
//  File.swift
//
//
//  Created by lmcmz on 23/9/21.
//

import AuthenticationServices
import Foundation

public class FlowAuthentication: NSObject {
    public static let shared = FlowAuthentication()
    public var delegate: FlowAuthDelegate?
    private var canContinue = true
    private var session: ASWebAuthenticationSession?

    public func authenticate(completion: @escaping (FlowResponse<FlowData>) -> Void) {
        let url = URL(string: "https://dapper-http-post.vercel.app/api/authn")!
        execHttpPost(url: url) { response in
            response.whenSuccess { result in
                guard let address = result.data?.addr else {
                    completion(FlowResponse.failure(error: FError.invalidResponse))
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
                completion(FlowResponse.failure(error: FError.invalidResponse))
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
                    completion(FlowResponse.failure(error: FError.declined))
                case .pending:
                    self.canContinue = true
                    guard let local = result.local, let updates = result.updates else {
                        completion(FlowResponse.failure(error: FError.generic))
                        return
                    }
                    guard let url = URL(string: local.endpoint) else {
                        completion(FlowResponse.failure(error: FError.urlInvaild))
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
            completion(FlowResponse.failure(error: FError.declined))
            return
        }

        guard let url = URL(string: service.endpoint) else {
            completion(FlowResponse.failure(error: FError.urlInvaild))
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
                    completion(FlowResponse.failure(error: FError.declined))
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
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    private func closeSession() {
        DispatchQueue.main.async {
            self.session?.cancel()
        }
    }
}

extension FlowAuthentication: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = self.delegate?.presentationAnchor() {
            return anchor
        }
        return ASPresentationAnchor()
    }
}
