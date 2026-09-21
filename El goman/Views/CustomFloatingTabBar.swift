//
//  CustomFloatingTabBar.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct CustomFloatingTabBar: View {
    @Binding var selectedTab: ContentView.TabItem
    let cartCount: Int
    let onSearchTap: () -> Void

    public init(
        selectedTab: Binding<ContentView.TabItem>,
        cartCount: Int,
        onSearchTap: @escaping () -> Void
    ) {
        self._selectedTab = selectedTab
        self.cartCount = cartCount
        self.onSearchTap = onSearchTap
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Fondo blanco redondeado de la barra flotante
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.white)
                .frame(height: 74)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 6)

            // Contenedor horizontal de items
            HStack(alignment: .center, spacing: 0) {
                
                // 1. LISTA
                tabButton(
                    title: "LISTA",
                    icon: "list.bullet.rectangle",
                    tab: .cart,
                    badgeCount: cartCount
                )

                // 2. OFERTAS
                tabButton(
                    title: "OFERTAS",
                    icon: "tag.fill",
                    tab: .offers
                )

                // Espacio central para el botón flotante BUSCAR
                Spacer()
                    .frame(width: 76)

                // 4. PERFIL
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .profile
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 26, height: 26)
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 26, height: 26)
                                .foregroundColor(selectedTab == .profile ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                        }

                        Text("PERFIL")
                            .font(.montserrat(.black, size: 9))
                            .tracking(0.5)
                            .foregroundColor(selectedTab == .profile ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                // 5. ESCANEAR (con badge "MUY PRONTO")
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .scanner
                }) {
                    VStack(spacing: 4) {
                        // Badge "MUY PRONTO"
                        Text("MUY PRONTO")
                            .font(.montserrat(.black, size: 7))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.98, green: 0.55, blue: 0.08)) // Naranja
                            .clipShape(Capsule())
                            .offset(y: -2)

                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == .scanner ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))

                        Text("ESCANEAR")
                            .font(.montserrat(.black, size: 9))
                            .tracking(0.5)
                            .foregroundColor(selectedTab == .scanner ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 74)

            // Botón central flotante BUSCAR
            VStack(spacing: 4) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedTab = .home
                    onSearchTap()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.06, green: 0.10, blue: 0.16)) // Azul oscuro / negro
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 5)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Text("BUSCAR")
                    .font(.montserrat(.black, size: 9))
                    .tracking(0.8)
                    .foregroundColor(selectedTab == .home ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .offset(y: -22) // Eleva el botón sobre la barra
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Botón genérico de pestaña
    private func tabButton(
        title: String,
        icon: String,
        tab: ContentView.TabItem,
        badgeCount: Int = 0
    ) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(selectedTab == tab ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                        .frame(height: 26)

                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.montserrat(.bold, size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.13, green: 0.77, blue: 0.36))
                            .clipShape(Capsule())
                            .offset(x: 14, y: -4)
                    }
                }

                Text(title)
                    .font(.montserrat(.black, size: 9))
                    .tracking(0.5)
                    .foregroundColor(selectedTab == tab ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
