//
//  MangoLogoView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct MangoLogoView: View {
    var width: CGFloat = 120

    public init(width: CGFloat = 120) {
        self.width = width
    }

    // Keep size initializer for backwards compatibility
    public init(size: CGFloat) {
        self.width = size
    }

    public var body: some View {
        Image("elmango-logo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
    }
}
