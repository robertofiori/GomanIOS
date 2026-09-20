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
        VStack(spacing: 18) {
            // Fila de Encabezado: Logo Mango + Tipografía
            HStack(alignment: .center, spacing: 14) {
                // Logo Mango con carrito
                MangoLogoView(size: 92)

                // Texto "¡Ahorra en tu compra realmente!"
                VStack(alignment: .leading, spacing: -2) {
                    Text("¡Ahorra")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.07, green: 0.10, blue: 0.17))

                    Text("en tu")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.07, green: 0.10, blue: 0.17))

                    Text("compra")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.07, green: 0.10, blue: 0.17))

                    Text("realmente!")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .italic()
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36)) // Verde vibrante
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 4)
            .padding(.horizontal, 4)

            // Input de Búsqueda con Botón "Ir"
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    .padding(.leading, 14)

                TextField("Ej. Aceite Natura, Leche..", text: $searchText)
                    .focused($isSearchFocused)
                    .font(.system(size: 15, weight: .medium))
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 40)
                        .background(Color(red: 0.44, green: 0.84, blue: 0.56)) // Verde claro suave
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .frame(height: 52)
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
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))

                    Text(appState.selectedLocation.city)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                }

                Spacer()

                // Botón "CAMBIAR"
                Button(action: {
                    showLocationPicker = true
                }) {
                    Text("CAMBIAR")
                        .font(.system(size: 11, weight: .heavy))
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
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Spacer()

                Button(action: {
                    onNavigateToCart()
                }) {
                    Text("VER TODO")
                        .font(.system(size: 11, weight: .heavy))
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                    .lineLimit(1)

                Text(formatPrice(item.selectedPrice.price * Double(item.quantity)))
                    .font(.system(size: 16, weight: .black, design: .rounded))
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
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                }
                .buttonStyle(.plain)

                Text("\(item.quantity)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                    .frame(minWidth: 16)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    appState.updateQuantity(for: item, delta: 1)
                }) {
                    Text("+")
                        .font(.system(size: 17, weight: .bold))
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Text("$ 1.990")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
            }

            Spacer()

            Button(action: {
                searchText = "arroz"
                performSearch(query: "arroz")
            }) {
                Text("+ Agregar")
                    .font(.system(size: 12, weight: .bold))
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
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

                Spacer()

                Button("Cerrar") {
                    searchResults = []
                    searchText = ""
                    errorMessage = nil
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Buscando mejores precios...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color.white.cornerRadius(24))
                .padding(.horizontal, 16)
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white.cornerRadius(24))
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(searchResults) { price in
                        ProductSearchResultRow(price: price) {
                            appState.addToCart(
                                productName: price.productName ?? searchText,
                                brand: price.brand,
                                imageUrl: price.imageUrl,
                                selectedPrice: price,
                                allPrices: searchResults,
                                quantity: 1,
                                ean: price.ean
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.cornerRadius(18))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Location Picker Sheet
    private var locationPickerSheet: some View {
        NavigationStack {
            List(LocationData.availableLocations) { loc in
                Button(action: {
                    appState.selectedLocation = loc
                    showLocationPicker = false
                    if !searchText.isEmpty {
                        performSearch(query: searchText)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.city)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(loc.province) • CP \(loc.zipCode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appState.selectedLocation.id == loc.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar Ciudad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showLocationPicker = false }
                }
            }
        }
    }

    private func performSearch(query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        appState.addRecentSearch(clean)
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let prices = try await PriceService.shared.searchPrices(
                    query: clean,
                    location: appState.selectedLocation
                )
                await MainActor.run {
                    self.searchResults = prices
                    self.isLoading = false
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
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
