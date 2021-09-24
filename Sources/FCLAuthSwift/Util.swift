//
//  File.swift
//
//
//  Created by lmcmz on 24/9/21.
//

import AuthenticationServices
import Foundation

public protocol FCLAuthDelegate {
    func showLoading()
    func hideLoading()
}

extension FCLAuthDelegate {
    func presentationAnchor() -> UIWindow {
        return ASPresentationAnchor()
    }
}
