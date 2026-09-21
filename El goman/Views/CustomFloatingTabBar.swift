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
        ZStack(alignment: .bottom) {
            // Fondo de la barra flotante con sombra suave
            HStack(spacing: 0) {
                // 1. LISTA
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .cart
                }) {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "list.number")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == .cart ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))

                            if cartCount > 0 {
                                Text("\(cartCount)")
                                    .font(.montserrat(.black, size: 9))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color(red: 0.13, green: 0.77, blue: 0.36))
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -8)
                            }
                        }

                        Text("LISTA")
                            .font(.montserrat(.black, size: 9))
                            .tracking(0.5)
                            .foregroundColor(selectedTab == .cart ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                // 2. OFERTAS
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .offers
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == .offers ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))

                        Text("OFERTAS")
                            .font(.montserrat(.black, size: 9))
                            .tracking(0.5)
                            .foregroundColor(selectedTab == .offers ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

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
                            if let data = AuthService.shared.currentUser?.avatarImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 26, height: 26)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedTab == .profile ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color.clear, lineWidth: 2)
                                    )
                            } else {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 26, height: 26)
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(selectedTab == .profile ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                            }
                        }

                        Text("PERFIL")
                            .font(.montserrat(.black, size: 9))
                            .tracking(0.5)
                            .foregroundColor(selectedTab == .profile ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                // 5. ESCANEAR (con badge "PRONTO")
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = .scanner
                }) {
                    VStack(spacing: 3) {
                        // Badge "PRONTO"
                        Text("PRONTO")
                            .font(.montserrat(.black, size: 7))
                            .tracking(0.2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.98, green: 0.55, blue: 0.08)) // Naranja
                            .clipShape(Capsule())
                            .lineLimit(1)
                            .fixedSize()
                            .offset(y: -2)

                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 19))
                            .foregroundColor(selectedTab == .scanner ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))

                        Text("ESCANEAR")
                            .font(.montserrat(.black, size: 8))
                            .tracking(0.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundColor(selectedTab == .scanner ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            // Botón central flotante BUSCAR
            VStack(spacing: 4) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedTab = .home
                    onSearchTap()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.13, green: 0.77, blue: 0.36)) // Verde principal
                            .frame(width: 58, height: 58)
                            .shadow(color: Color(red: 0.13, green: 0.77, blue: 0.36).opacity(0.4), radius: 10, x: 0, y: 5)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(y: -28)

                Text("BUSCAR")
                    .font(.montserrat(.black, size: 9))
                    .tracking(0.5)
                    .foregroundColor(selectedTab == .home ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    .offset(y: -26)
            }
        }
    }
}
