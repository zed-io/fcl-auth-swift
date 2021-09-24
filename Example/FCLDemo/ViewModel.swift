//
//  FCLDemo
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
        
        let service = FlowWalletService(
            id: "foo",
            name: "bar",
            method: .post,
            endpoint: URL(string: "https://dapper-http-post.vercel.app/api/")!
        )

        FCL.shared.config(
            app: FlowAppData(
                title: "FCL iOS Demo",
                icon: URL(string: "https://foo.com/bar.png")!
            ),
            // default provider is  [.dapper, .blocto]
            providers: [.dapper, .blocto, .custom(service)]
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

extension ViewModel: FlowAuthDelegate {
    func showLoading() {
        isLoading = true
    }

    func hideLoading() {
        isLoading = false
    }
}
