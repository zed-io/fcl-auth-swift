//
//  ContentView.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
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
                                    viewModel.videoURL = URL(string: nft.metadata.image.black)!
                                }) {
                                    VStack {
                                        AsyncImage(url: URL(string: nft.metadata.image.hero)!) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 200, height: 200, alignment: .center)
                                        .cornerRadius(30)
                                        .padding(10)

                                        Text(nft.metadata.play.stats.playerName)
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

    fileprivate func authenticate() -> Section<EmptyView, TupleView<(HStack<TupleView<(Button<Text>, Spacer, ProgressView<EmptyView, EmptyView>?)>>, Text)>, EmptyView> {
        return Section {
            HStack {
                Button("Auth") {
                    viewModel.authn()
                }
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            Text(verbatim: viewModel.address)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
