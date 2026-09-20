//
//  ContentView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct ContentView: View {
    @State private var appState = AppState()
    @State private var selectedTab: TabItem = .home

    public enum TabItem: Int, Hashable {
        case home = 0
        case cart = 1
        case offers = 2
        case scanner = 3
        case profile = 4
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "magnifyingglass")
                }
                .tag(TabItem.home)

            CartView()
                .tabItem {
                    Label("Mi Lista", systemImage: "cart.fill")
                }
                .badge(appState.totalCartUnitsCount > 0 ? "\(appState.totalCartUnitsCount)" : nil)
                .tag(TabItem.cart)

            OffersView()
                .tabItem {
                    Label("Ofertas", systemImage: "tag.fill")
                }
                .tag(TabItem.offers)

            ScannerView()
                .tabItem {
                    Label("Escanear", systemImage: "barcode.viewfinder")
                }
                .tag(TabItem.scanner)

            ProfileView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(TabItem.profile)
        }
        .tint(.green)
        .environment(appState)
    }
}

#Preview {
    ContentView()
}
