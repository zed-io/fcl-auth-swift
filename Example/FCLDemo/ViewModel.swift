//
//  ViewModel.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
//

import FlowAuthenticationService
import Foundation
import UIKit

class ViewModel: ObservableObject {
    @Published var address: String = ""

    @Published var isLoading: Bool = false

    init() {
        FCL.shared.delegate = self
        FCL.shared.config(app: FlowAppData(title: "FCL Demo",
                                           icon: URL(string: "https://foo.com/bar.png")!))
    }

    func authn() {
        FCL.shared.authenticate(provider: .dapper) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    self.address = data.address
                case let .failure(error):
                    self.address = error.localizedDescription
                }
            }
        }
    }
}

extension ViewModel: FlowAuthDelegate {
    func showLoading() {
        isLoading = true
    }

    func hideLoading() {
        isLoading = false
    }
}
