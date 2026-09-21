//
//  HomeView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct HomeView: View {
    @Environment(AppState.self) private var appState
    let onNavigateToCart: () -> Void

    @State private var searchText = ""
    @State private var searchResults: [SupermarketPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSupermarketFilter: String? = nil
    @State private var showLocationPicker = false
    @FocusState private var isSearchFocused: Bool

    public init(onNavigateToCart: @escaping () -> Void = {}) {
        self.onNavigateToCart = onNavigateToCart
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gris suave / off-white
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {

                        // 1. Tarjeta Blanca Superior Principal (Hero Card)
                        heroTopCard

                        // 2. Si hay una búsqueda activa con resultados, mostrar los resultados
                        if !searchResults.isEmpty || isLoading || errorMessage != nil {
                            searchResultsSection
                        } else {
                            // 3. Sección "Mi Lista"
                            myListSection
                        }

                        // Espacio para la barra de navegación flotante inferior
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, 6)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationPicker) {
                locationPickerSheet
            }
        }
    }

    // MARK: - Tarjeta Blanca Superior (Hero Card)
    private var heroTopCard: some View {
        VStack(spacing: 16) {
            // Fila de Encabezado: Logo Mango + Tipografía exacta Montserrat
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    // Logo Mango SVG original
                    MangoLogoView(width: 125)
                        .scaleEffect(1.08)

                    // Textos "¡Ahorra en tu compra" con Montserrat Black
                    VStack(alignment: .leading, spacing: -6) {
                        Text("¡Ahorra")
                            .font(.montserrat(.black, size: 42))
                            .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16)) // slate-950

                        Text("en tu")
                            .font(.montserrat(.black, size: 42))
                            .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))

                        Text("compra")
                            .font(.montserrat(.black, size: 42))
                            .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                    }
                }

                // "realmente!" con Montserrat Black Italic y verde #22c55e
                HStack(spacing: 0) {
                    Text("realmente")
                        .font(.montserrat(.blackItalic, size: 54))
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.37)) // primary-green

                    Text("!")
                        .font(.montserrat(.black, size: 54))
                        .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                }
                .padding(.top, -2)
                .padding(.bottom, 6)
            }
            .padding(.top, 4)

            // Input de Búsqueda con Botón "Ir"
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    .padding(.leading, 14)

                TextField("Ej. Aceite Natura, Leche..", text: $searchText)
                    .focused($isSearchFocused)
                    .font(.montserrat(.semiBold, size: 15))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch(query: searchText)
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        errorMessage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Botón "Ir" Verde
                Button(action: {
                    isSearchFocused = false
                    performSearch(query: searchText)
                }) {
                    Text("Ir")
                        .font(.montserrat(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 42)
                        .background(Color(red: 0.44, green: 0.84, blue: 0.56)) // Verde claro suave
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .frame(height: 54)
            .background(Color(red: 0.93, green: 0.95, blue: 0.98)) // Gris azulado suave
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Selector de Ubicación
            HStack(spacing: 12) {
                // Cuadro blanco con icono de pin
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 42, height: 42)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                }

                // Textos de Ubicación
                VStack(alignment: .leading, spacing: 2) {
                    Text("UBICACIÓN")
                        .font(.montserrat(.extraBold, size: 9))
                        .tracking(1.0)
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))

                    Text(appState.selectedLocation.city)
                        .font(.montserrat(.bold, size: 15))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                }

                Spacer()

                // Botón "CAMBIAR"
                Button(action: {
                    showLocationPicker = true
                }) {
                    Text("CAMBIAR")
                        .font(.montserrat(.black, size: 11))
                        .tracking(0.5)
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color(red: 0.88, green: 0.95, blue: 0.90), lineWidth: 1.5)
                                .background(Color.white.clipShape(Capsule()))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color(red: 0.98, green: 0.99, blue: 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.92, green: 0.94, blue: 0.96), lineWidth: 1)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Sección "Mi Lista"
    private var myListSection: some View {
        VStack(spacing: 14) {
            // Encabezado "Mi Lista" + "VER TODO"
            HStack(spacing: 12) {
                // Icono canasta verde
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.90, green: 0.98, blue: 0.93))
                        .frame(width: 40, height: 40)

                    Image(systemName: "basket.fill")
                        .font(.system(size: 19))
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                }

                Text("Mi Lista")
                    .font(.montserrat(.black, size: 22))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Spacer()

                Button(action: {
                    onNavigateToCart()
                }) {
                    Text("VER TODO")
                        .font(.montserrat(.black, size: 11))
                        .tracking(0.5)
                        .foregroundColor(Color(red: 0.28, green: 0.34, blue: 0.42))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.93, green: 0.95, blue: 0.98))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            // Tarjeta de Productos en la Lista
            VStack(spacing: 12) {
                if appState.cartItems.isEmpty {
                    // Item representativo / sugerido cuando la lista está vacía
                    emptyListPreviewCard
                } else {
                    // Elementos reales de la lista
                    ForEach(appState.cartItems.prefix(3)) { item in
                        cartPreviewRow(item)
                        if item.id != appState.cartItems.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Fila de Previsualización de Producto en Lista
    private func cartPreviewRow(_ item: CartItem) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Miniatura
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .frame(width: 58, height: 58)

                if let img = item.imageUrl, let url = URL(string: img) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .foregroundColor(.orange)
                }
            }

            // Nombre y Precio
            VStack(alignment: .leading, spacing: 3) {
                Text("Búsqueda: \(item.productName.lowercased())")
                    .font(.montserrat(.bold, size: 14))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                    .lineLimit(1)

                Text(formatPrice(item.selectedPrice.price * Double(item.quantity)))
                    .font(.montserrat(.extraBold, size: 16))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
            }

            Spacer()

            // Stepper Pill (-  Q  +)
            HStack(spacing: 12) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appState.updateQuantity(for: item, delta: -1)
                }) {
                    Text("—")
                        .font(.montserrat(.bold, size: 13))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                }
                .buttonStyle(.plain)

                Text("\(item.quantity)")
                    .font(.montserrat(.bold, size: 15))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                    .frame(minWidth: 16)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appState.updateQuantity(for: item, delta: 1)
                }) {
                    Text("+")
                        .font(.montserrat(.bold, size: 17))
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(red: 0.94, green: 0.96, blue: 0.98))
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Estado sugerido cuando la lista está vacía
    private var emptyListPreviewCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                    .frame(width: 58, height: 58)

                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Búsqueda: arroz parboil")
                    .font(.montserrat(.bold, size: 13))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Text("$ 1.990")
                    .font(.montserrat(.extraBold, size: 16))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
            }

            Spacer()

            Button(action: {
                searchText = "arroz"
                performSearch(query: "arroz")
            }) {
                Text("+ Agregar")
                    .font(.montserrat(.bold, size: 12))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.90, green: 0.98, blue: 0.93))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sección de Resultados de Búsqueda
    private var searchResultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resultados para \"\(searchText)\"")
                    .font(.montserrat(.bold, size: 18))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Spacer()

                Button("Cerrar") {
                    searchResults = []
                    searchText = ""
                    errorMessage = nil
                }
                .font(.montserrat(.semiBold, size: 13))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Comparando precios en Bahía Blanca...")
                        .font(.montserrat(.regular, size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                .padding(.horizontal, 16)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.montserrat(.regular, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                .padding(.horizontal, 16)
            } else {
                ForEach(searchResults) { price in
                    ProductSearchResultRow(price: price) {
                        appState.addToCart(price)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Sheet de Selección de Sucursal / Ubicación
    private var locationPickerSheet: some View {
        NavigationStack {
            List {
                Section("Ciudad") {
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

                Section("Supermercados activos") {
                    ForEach(["Carrefour", "Vea", "ChangoMás", "Cooperativa Obrera"], id: \.self) { superm in
                        HStack {
                            SupermarketBadge(superm, style: .compact)
                            Spacer()
                            Text("Bahía Blanca")
                                .font(.montserrat(.regular, size: 13))
                                .foregroundColor(.secondary)
                        }
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

    // MARK: - Lógica de Búsqueda
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let results = try await PriceService.shared.searchPrices(query: query, location: appState.selectedLocation)
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                    if results.isEmpty {
                        self.errorMessage = "No se encontraron productos para \"\(query)\""
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_AR")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
