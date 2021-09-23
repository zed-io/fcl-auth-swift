//
//  ViewModel.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
//

import Combine
import FlowAuthenticationService
import Foundation
import UIKit

class ViewModel: ObservableObject {
    @Published var address: String = ""

    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        FlowAuthentication.shared.delegate = self
    }

    func authn() {
        FlowAuthentication.shared.authenticate { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    self.address = data.address
                case let .failure(error):
                    self.address = error.localizedDescription
                }
            }
        }

//        FAuthentication.shared.authenticate()
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                if case let .failure(error) = completion {
//                    self.address = error.localizedDescription
//                }
//            } receiveValue: { data in
//                self.address = data.address
//            }.store(in: &cancellables)
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
