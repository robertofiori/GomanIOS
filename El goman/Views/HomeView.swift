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
    @State private var suggestions: [ProductSuggestion] = []
    @State private var isLoading = false
    @State private var isLoadingSuggestions = false
    @State private var errorMessage: String?
    @State private var showLocationPicker = false
    @State private var searchTask: Task<Void, Never>? = nil
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

                        // 1. Tarjeta Blanca Superior Principal (Hero Card con Buscador y Sugerencias)
                        heroTopCard

                        // 2. Si hay una búsqueda activa con resultados o carga
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

            // Input de Búsqueda con Sugerencias Desplegables
            VStack(spacing: 8) {
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
                            suggestions = []
                            performSearch(query: searchText)
                        }
                        .onChange(of: searchText) { _, newValue in
                            handleSearchTextChange(newValue)
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            suggestions = []
                            searchResults = []
                            errorMessage = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }

                    // Botón "Ir" Verde
                    Button(action: {
                        isSearchFocused = false
                        suggestions = []
                        performSearch(query: searchText)
                    }) {
                        Text("Ir")
                            .font(.montserrat(.bold, size: 16))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 42)
                            .background(Color(red: 0.13, green: 0.77, blue: 0.36)) // Verde consistente
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                }
                .frame(height: 54)
                .background(Color(red: 0.93, green: 0.95, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSearchFocused ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color.clear, lineWidth: 2)
                )

                // DROPDOWN DE SUGERENCIAS EN VIVO (Referencia: search1.jpg)
                if !suggestions.isEmpty && isSearchFocused {
                    suggestionsDropdownCard
                }
            }

            // Selector de Ubicación
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 42, height: 42)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                }

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

    // MARK: - Dropdown Card de Sugerencias en Vivo
    private var suggestionsDropdownCard: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.prefix(6)) { item in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    searchText = item.name
                    suggestions = []
                    isSearchFocused = false
                    performSearch(query: item.ean ?? item.name)
                }) {
                    HStack(spacing: 12) {
                        // Thumbnail
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
                                .frame(width: 44, height: 44)

                            if let img = item.imageUrl, let url = URL(string: img) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 36, height: 36)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.60, green: 0.65, blue: 0.72))
                                    }
                                }
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.60, green: 0.65, blue: 0.72))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.montserrat(.bold, size: 14))
                                .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                                .lineLimit(1)

                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand.uppercased())
                                    .font(.montserrat(.semiBold, size: 10))
                                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.78, green: 0.82, blue: 0.88))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if item.id != suggestions.prefix(6).last?.id {
                    Divider()
                        .padding(.horizontal, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Sección "Mi Lista"
    private var myListSection: some View {
        VStack(spacing: 14) {
            // Encabezado "Mi Lista" + "VER TODO"
            HStack(spacing: 12) {
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
                    emptyListPreviewCard
                } else {
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

    private func cartPreviewRow(_ item: CartItem) -> some View {
        HStack(alignment: .center, spacing: 14) {
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

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.productName)
                        .font(.montserrat(.bold, size: 14))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .lineLimit(1)

                    if item.isOptional {
                        Text("OPCIONAL")
                            .font(.montserrat(.bold, size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.93, green: 0.12, blue: 0.47))
                            .clipShape(Capsule())
                    }
                }

                Text(formatPrice(item.selectedPrice.price * Double(item.quantity)))
                    .font(.montserrat(.extraBold, size: 16))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
            }

            Spacer()

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
        VStack(spacing: 14) {
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
                let lowestPrice = searchResults.filter { $0.inStock && $0.price > 0 }.map(\.price).min()
                ForEach(searchResults) { price in
                    let isBest = (price.price == lowestPrice && price.inStock && price.price > 0)
                    ProductSearchResultRow(
                        price: price,
                        isBestPrice: isBest,
                        bestSavingsVsHighest: nil
                    ) { qty, isOptional in
                        appState.addToCart(price, quantity: qty, isOptional: isOptional)
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

    // MARK: - Sugerencias en Vivo
    private func handleSearchTextChange(_ query: String) {
        searchTask?.cancel()
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            suggestions = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            if Task.isCancelled { return }
            let results = await PriceService.shared.fetchSuggestions(query: query)
            if !Task.isCancelled {
                await MainActor.run {
                    self.suggestions = results
                }
            }
        }
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
