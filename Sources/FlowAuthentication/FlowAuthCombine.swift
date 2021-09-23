import AuthenticationServices
import Combine
import Foundation

// Using combine, only available for iOS 13+
public class FAuthentication: NSObject {
    public static let shared = FAuthentication()
    private var cancellables = Set<AnyCancellable>()
    private var canContinue = true
    private var session: ASWebAuthenticationSession?

    public func authenticate() -> AnyPublisher<FlowData, Error> {
        let url = URL(string: "https://dapper-http-post.vercel.app/api/authn")!
        return execHttpPost(url: url)
            .tryMap { response in
                guard let address = response.data?.addr else {
                    throw FError.invalidResponse
                }
                return FlowData(address: address)
            }
            .eraseToAnyPublisher()
    }

    private func fetchService(url: URL) -> AnyPublisher<AuthnResponse, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // TODO: Need to check extract config
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config).dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: AuthnResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    private func execHttpPost(url: URL) -> Future<AuthnResponse, Error> {
        return Future { promise in
            self.fetchService(url: url)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print(error)
                    }
                } receiveValue: { result in
                    switch result.status {
                    case .approved:
                        promise(.success(result))
                    case .declined:
                        promise(.failure(FError.declined))
                    case .pending:
                        self.canContinue = true
                        guard let local = result.local, let updates = result.updates else {
                            promise(.failure(FError.generic))
                            return
                        }
                        guard let url = URL(string: local.endpoint) else {
                            promise(.failure(FError.urlInvaild))
                            return
                        }
                        self.openAuthenticationSession(url: url)
                        self.poll(service: updates).sink { completion in
                            if case let .failure(error) = completion {
                                promise(.failure(error))
                            }
                        } receiveValue: { result in
                            promise(.success(result))
                        }.store(in: &self.cancellables)
                    }
                }.store(in: &self.cancellables)
        }
    }

    private func poll(service: Service) -> Future<AuthnResponse, Error> {
        return Future { promise in

            if !self.canContinue {
                promise(.failure(FError.declined))
                return
            }

            guard let url = URL(string: service.endpoint) else {
                promise(.failure(FError.urlInvaild))
                return
            }

            self.fetchService(url: url)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print(error)
                    }
                } receiveValue: { result in
                    print("polling ---> \(result.status.rawValue)")
                    switch result.status {
                    case .approved:
                        self.closeSession()
                        promise(.success(result))
                    case .declined:
                        promise(.success(result))
                    case .pending:
                        // TODO: Improve this
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                            self.poll(service: service)
                                .sink { completion in
                                    if case let .failure(error) = completion {
                                        promise(.failure(error))
                                    }
                                } receiveValue: { result in
                                    promise(.success(result))
                                }
                                .store(in: &self.cancellables)
                        }
                    }
                }.store(in: &self.cancellables)
        }
    }
    
    private func openAuthenticationSession(url: URL) {
        DispatchQueue.main.async {
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

extension FAuthentication: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
