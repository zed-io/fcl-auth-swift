//
//  ContentView.swift
//  FCLDemo
//
//  Created by lmcmz on 30/8/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Button("Auth") {
                            viewModel.authn()
                        }
                        Spacer(minLength: 0)
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                    Text(verbatim: viewModel.address)
                }
            }.navigationTitle("FCL-Swift Demo")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
