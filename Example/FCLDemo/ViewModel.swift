//
//  ViewModel.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
//

import AVKit
import FCLAuthSwift
import Foundation
import UIKit

class ViewModel: ObservableObject {
    @Published var address: String = ""

    @Published var isLoading: Bool = false

    @Published var isPlayVideo: Bool = false

    @Published var videoURL: URL? = nil

    @Published var nfts: [NFTModel] = []

    init() {
        FCL.shared.delegate = self
        
        let provider = FCLWalletProvider(
            id: "foo",
            name: "bar",
            method: .httpPost,
            endpoint: URL(string: "https://dapper-http-post.vercel.app/api/authn")!
        )

        FCL.shared.config(
            application: FCLApplication(
                title: "FCL iOS Demo",
                icon: URL(string: "https://foo.com/bar.png")!
            ),
            // default provider is  [.dapper, .blocto]
            providers: [.dapper, .blocto, .custom(provider)]
        )
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
                    self.fetchNFTs()
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

    func fetchNFTs() {
        FCL.shared.fetchNFTs(address: address) { result in
            result.whenSuccess { response in
                self.nfts = response.nfts
            }

            result.whenFailure { _ in
            }
        }
    }
}

extension ViewModel: FCLAuthDelegate {
    func showLoading() {
        isLoading = true
    }

    func hideLoading() {
        isLoading = false
    }
}
