//
//  File.swift
//
//
//  Created by lmcmz on 22/9/21.
//

import Foundation

public struct FlowData: Decodable {
    public let address: String
    // TODO: Add more object
}

public struct FlowAppData {
    public let title: String
    public let icon: URL

    public init(title: String, icon: URL) {
        self.title = title
        self.icon = icon
    }
}
