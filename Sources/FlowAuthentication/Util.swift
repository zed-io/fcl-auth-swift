//
//  File.swift
//  
//
//  Created by lmcmz on 24/9/21.
//

import Foundation
import AuthenticationServices

public protocol FlowAuthDelegate {
    func showLoading()
    func hideLoading()
}

extension FlowAuthDelegate {
    func presentationAnchor() -> UIWindow {
        return ASPresentationAnchor()
    }
}

public enum FlowResponse<T: Codable> {
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
