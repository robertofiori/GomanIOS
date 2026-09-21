//
//  ProfileView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI
import PhotosUI

public struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var authService = AuthService.shared

    @State private var activeTab: ProfileTab = .settings
    @State private var showLocationPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var avatarImage: Image? = nil

    public enum ProfileTab {
        case settings
        case payments
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gris suave (#f7f8fa)
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {

                        // 1. Tarjeta Superior: Avatar + Nombre + Email
                        userHeaderCard

                        // 2. Tabs: AJUSTES / PAGOS
                        tabsSelector

                        // 3. Contenido según tab activo
                        if activeTab == .settings {
                            settingsSection
                        } else {
                            paymentsSection
                        }

                        // 4. Tarjeta "¡Ayudanos a crecer!"
                        shareAppCard

                        // 5. Aviso Legal
                        legalDisclaimerCard

                        // Espacio para la barra de navegación flotante
                        Spacer()
                            .frame(height: 110)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationPicker) {
                locationPickerSheet
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        authService.updateAvatar(imageData: data)
                        if let uiImage = UIImage(data: data) {
                            avatarImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            .onAppear {
                if let data = authService.currentUser?.avatarImageData, let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    // MARK: - 1. Tarjeta de Usuario y Avatar
    private var userHeaderCard: some View {
        VStack(spacing: 14) {
            // Avatar con botón de cámara
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(Color(red: 0.92, green: 0.94, blue: 0.97))
                        .frame(width: 112, height: 112)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                    if let avatar = avatarImage {
                        avatar
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    } else if let photoURL = authService.currentUser?.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 112, height: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                            } else {
                                defaultAvatarPlaceholder
                            }
                        }
                    } else {
                        defaultAvatarPlaceholder
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white, lineWidth: 6)
                )

                // Botón de cámara verde con PhotosPicker
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.13, green: 0.77, blue: 0.36)) // primary-green
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white, lineWidth: 3)
                    )
                }
                .offset(x: 4, y: 4)
            }
            .padding(.top, 10)

            // Nombre y Email
            VStack(spacing: 4) {
                Text(authService.currentUser?.displayName ?? "Roberto Fiori")
                    .font(.montserrat(.black, size: 24))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Text(authService.currentUser?.email ?? "farenheit.com@gmail.com")
                    .font(.montserrat(.bold, size: 14))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
        )
    }

    private var defaultAvatarPlaceholder: some View {
        ZStack {
            Color(red: 0.93, green: 0.95, blue: 0.98)
            Image(systemName: "person.fill")
                .font(.system(size: 46))
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
        }
        .frame(width: 112, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    // MARK: - 2. Selector de Tabs (Ajustes / Pagos)
    private var tabsSelector: some View {
        HStack(spacing: 6) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                activeTab = .settings
            }) {
                Text("AJUSTES")
                    .font(.montserrat(.black, size: 12))
                    .tracking(1.0)
                    .foregroundColor(activeTab == .settings ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        activeTab == .settings
                            ? Color.white
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: activeTab == .settings ? Color.black.opacity(0.05) : Color.clear, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                activeTab = .payments
            }) {
                Text("PAGOS")
                    .font(.montserrat(.black, size: 12))
                    .tracking(1.0)
                    .foregroundColor(activeTab == .payments ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.58, green: 0.64, blue: 0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        activeTab == .payments
                            ? Color.white
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: activeTab == .payments ? Color.black.opacity(0.05) : Color.clear, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(5)
        .background(Color(red: 0.93, green: 0.95, blue: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - 3. Sección Ajustes
    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Localización Actual
            Button(action: {
                showLocationPicker = true
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
                            .frame(width: 44, height: 44)

                        Image(systemName: "mappin")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Localización Actual")
                            .font(.montserrat(.bold, size: 15))
                            .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                        Text("\(appState.selectedLocation.city.uppercased()), CP \(appState.selectedLocation.zipCode)")
                            .font(.montserrat(.bold, size: 11))
                            .tracking(0.5)
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.88))
                }
                .padding(18)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.horizontal, 18)

            // Notificaciones
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.92, green: 0.95, blue: 1.0))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Notificaciones")
                        .font(.montserrat(.bold, size: 15))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                    Text("Alertas de ofertas diarias")
                        .font(.montserrat(.semiBold, size: 11))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { authService.currentUser?.notificationsEnabled ?? true },
                    set: { authService.updateNotifications(enabled: $0) }
                ))
                .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
                .labelsHidden()
            }
            .padding(18)

            Divider()
                .padding(.horizontal, 18)

            // Cerrar Sesión
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                authService.signOut()
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.94, blue: 0.94))
                            .frame(width: 44, height: 44)

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.27))
                    }

                    Text("Cerrar Sesión")
                        .font(.montserrat(.bold, size: 15))
                        .foregroundColor(Color(red: 0.94, green: 0.27, blue: 0.27))

                    Spacer()
                }
                .padding(18)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
        )
    }

    // MARK: - 3b. Sección Pagos / Billeteras
    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mis Billeteras")
                    .font(.montserrat(.black, size: 20))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Text("Seleccioná las que usás para ver promos bancarias.")
                    .font(.montserrat(.semiBold, size: 13))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(availableWallets) { wallet in
                    let isSelected = authService.currentUser?.paymentMethods.contains(wallet.id) ?? false
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        authService.togglePaymentMethod(wallet.id)
                        appState.toggleBank(wallet.id)
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isSelected ? Color.white : Color(red: 0.94, green: 0.96, blue: 0.98))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: wallet.systemIcon)
                                        .font(.system(size: 20))
                                        .foregroundColor(isSelected ? wallet.themeColor : Color(red: 0.58, green: 0.64, blue: 0.72))
                                }

                                Spacer()

                                if isSelected {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 24, height: 24)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundColor(wallet.themeColor)
                                    }
                                }
                            }

                            Text(wallet.name)
                                .font(.montserrat(.black, size: 14))
                                .foregroundColor(isSelected ? .white : Color(red: 0.12, green: 0.16, blue: 0.24))
                                .lineLimit(1)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(isSelected ? wallet.themeColor : Color.white)
                                .shadow(color: isSelected ? wallet.themeColor.opacity(0.3) : Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 4. Tarjeta "¡Ayudanos a crecer!"
    private var shareAppCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("¡Ayudanos a crecer!")
                .font(.montserrat(.black, size: 19))
                .foregroundColor(.white)

            Text("ElMango es un proyecto gratuito para Bahía Blanca. Compartilo con tus conocidos para que todos ahorren.")
                .font(.montserrat(.semiBold, size: 14))
                .foregroundColor(Color(red: 0.80, green: 0.85, blue: 0.92))
                .lineSpacing(3)

            Button(action: {
                shareApp()
            }) {
                Text("Compartir App")
                    .font(.montserrat(.black, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.13, green: 0.77, blue: 0.36))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color(red: 0.13, green: 0.77, blue: 0.36).opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 0.08, green: 0.12, blue: 0.18)) // slate-900 / dark card
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: - 5. Aviso Legal
    private var legalDisclaimerCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.98, green: 0.55, blue: 0.08)) // orange

                Text("AVISO LEGAL")
                    .font(.montserrat(.extraBold, size: 11))
                    .tracking(1.5)
                    .foregroundColor(Color(red: 0.28, green: 0.34, blue: 0.42))
            }

            Text("LOS PRECIOS INDICADOS SON REFERENCIALES Y PUEDEN VARIAR EN CADA SUCURSAL. LOS NOMBRES DE LAS CADENAS (EJ: CARREFOUR, CHANGOMÁS) SE UTILIZAN ÚNICAMENTE CON FINES COMPARATIVOS E INFORMATIVOS Y SON PROPIEDAD DE SUS RESPECTIVOS DUEÑOS.")
                .font(.montserrat(.bold, size: 9))
                .tracking(0.5)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(red: 0.90, green: 0.92, blue: 0.95), lineWidth: 1)
                )
        )
    }

    // MARK: - Compartir App
    private func shareApp() {
        guard let url = URL(string: "https://robertofiori.github.io/superscan/") else { return }
        let text = "¡Mirá ElMango! La app para ahorrar en el supermercado en Bahía Blanca: \(url.absoluteString)"
        let av = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }

    // MARK: - Sheet de Ubicación
    private var locationPickerSheet: some View {
        NavigationStack {
            List {
                Section("Ciudad Actual") {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                        Text(appState.selectedLocation.city)
                            .font(.montserrat(.bold, size: 16))
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                    }
                }
            }
            .navigationTitle("Ubicación")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Listo") {
                        showLocationPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Wallets Disponibles
    private var availableWallets: [WalletItem] {
        [
            WalletItem(id: "cuentadni", name: "Cuenta DNI", themeColor: Color(red: 0.25, green: 0.69, blue: 0.50), systemIcon: "creditcard.fill"),
            WalletItem(id: "bnaplus", name: "BNA+", themeColor: Color(red: 0.0, green: 0.45, blue: 0.74), systemIcon: "building.columns.fill"),
            WalletItem(id: "modo", name: "MODO", themeColor: Color(red: 0.95, green: 0.75, blue: 0.0), systemIcon: "qrcode.viewfinder"),
            WalletItem(id: "mercadopago", name: "Mercado Pago", themeColor: Color(red: 0.0, green: 0.62, blue: 0.89), systemIcon: "wallet.pass.fill"),
            WalletItem(id: "ualá", name: "Ualá", themeColor: Color(red: 0.0, green: 0.16, blue: 1.0), systemIcon: "creditcard.and.123"),
            WalletItem(id: "brubank", name: "Brubank", themeColor: Color(red: 0.17, green: 0.19, blue: 0.22), systemIcon: "banknote.fill"),
            WalletItem(id: "lemon", name: "Lemon Cash", themeColor: Color(red: 0.11, green: 0.91, blue: 0.71), systemIcon: "bitcoinsign.circle.fill")
        ]
    }
}

// MARK: - Modelo de Billetera
private struct WalletItem: Identifiable {
    let id: String
    let name: String
    let themeColor: Color
    let systemIcon: String
}
