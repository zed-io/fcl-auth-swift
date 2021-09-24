//
//  ViewModel.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
//

import FCLAuthSwift
import Foundation
import UIKit

class ViewModel: ObservableObject {
    @Published var address: String = ""

    @Published var isLoading: Bool = false

    init() {
        FCL.shared.delegate = self
        let service = FlowWalletService(id: "foo",
                                        name: "bar",
                                        method: .post,
                                        endpoint: URL(string: "https://dapper-http-post.vercel.app/api/")!)

        FCL.shared.config(app: FlowAppData(title: "FCL Demo",
                                           icon: URL(string: "https://foo.com/bar.png")!),
                          // default provider is  [.dapper, .blocto]
                          providers: [.dapper, .blocto, .custom(service)])
    }

    func authn() {
        // Style 1
        // default provider is dapper
        // FCL.shared.authenticate { result in
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

        // Style 2
//        FCL.shared.authenticate(providerID: "foo") { response in
//            response.whenSuccess { data in
//                DispatchQueue.main.async {
//                    self.address = data.address
//                }
//            }
//
//            response.whenFailure { error in
//                DispatchQueue.main.async {
//                    self.address = error.localizedDescription
//                }
//            }
//        }
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
