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
        case profile = 3
        case scanner = 4
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido de las pestañas
            Group {
                switch selectedTab {
                case .home:
                    HomeView(onNavigateToCart: {
                        selectedTab = .cart
                    })
                case .cart:
                    CartView()
                case .offers:
                    OffersView()
                case .profile:
                    ProfileView()
                case .scanner:
                    ScannerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Barra Flotante Inferior Personalizada
            CustomFloatingTabBar(
                selectedTab: $selectedTab,
                cartCount: appState.totalCartUnitsCount,
                onSearchTap: {
                    selectedTab = .home
                }
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
        .environment(appState)
    }
}

#Preview {
    ContentView()
}
