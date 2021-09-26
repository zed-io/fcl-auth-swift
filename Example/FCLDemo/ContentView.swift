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
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            Form {
                authenticate()

                Section {
                    Button("Fetch NFTs") {
                        viewModel.fetchNFTs()
                    }
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [GridItem()], content: {
                            ForEach(viewModel.nfts, id: \.self) { nft in
                                Button(action: {
                                    viewModel.isPlayVideo.toggle()
                                    viewModel.videoURL = nft.metadata.topShotImages.black
                                }) {
                                    VStack {
                                        AsyncImage(url: nft.metadata.image) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 200, height: 200, alignment: .center)
                                        .cornerRadius(30)
                                        .padding(10)

                                        Text(nft.metadata.title)
                                    }
                                }
                            }
                        })
                    }
                }
            }.navigationTitle("FCL-Swift Demo")
        }.fullScreenCover(isPresented: $viewModel.isPlayVideo) {
            let player = AVPlayer(url: viewModel.videoURL!)
            VideoPlayer(player: player).onAppear {
                player.play()
            }.onDisappear {
                player.pause()
            }.edgesIgnoringSafeArea(.all)
        }
    }

    fileprivate func authenticate() -> some View {
        return Section {
            Button("Log in with Dapper") {
                viewModel.authn(provider: .dapper)
            }
            Button("Log in with Blocto") {
                viewModel.authn(provider: .blocto)
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(verbatim: viewModel.address)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
