//
//  El_gomanApp.swift
//  El goman
//
//  Created by Roberto Fiori on 02/07/2026.
//

import SwiftUI

@main
struct El_gomanApp: App {
    init() {
        FontRegistrar.registerFontsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
