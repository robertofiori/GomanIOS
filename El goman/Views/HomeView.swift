//
//  HomeView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var searchText = ""
    @State private var searchResults: [SupermarketPrice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSupermarketFilter: String? = nil
    @State private var showLocationPicker = false

    private let quickCategories = [
        ("Aceite", "drop.fill", Color.yellow),
        ("Leche", "cup.and.saucer.fill", Color.blue),
        ("Arroz", "takeoutbag.and.cup.and.straw.fill", Color.orange),
        ("Fideos", "fork.knife", Color.red),
        ("Limpieza", "bubbles.and.sparkles.fill", Color.cyan),
        ("Café", "mug.fill", Color.brown),
        ("Galletitas", "circle.hexagongrid.fill", Color.indigo)
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if !searchText.isEmpty {
                    searchResultsView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("ElMango")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showLocationPicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                            Text(appState.selectedLocation.city)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Ej. Aceite Natura, Leche..."
            )
            .onSubmit(of: .search) {
                performSearch(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    isLoading = false
                    errorMessage = nil
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                locationPickerSheet
            }
        }
    }

    // MARK: - Main Content (When not searching)
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                
                // Hero Banner de Ahorro
                heroBanner

                // Categorías Rápidas
                VStack(alignment: .leading, spacing: 10) {
                    Text("Categorías populares")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickCategories, id: \.0) { cat in
                                Button(action: {
                                    searchText = cat.0
                                    performSearch(query: cat.0)
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(cat.2.opacity(0.15))
                                                .frame(width: 56, height: 56)
                                            Image(systemName: cat.1)
                                                .font(.title3)
                                                .foregroundColor(cat.2)
                                        }
                                        Text(cat.0)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Búsquedas Recientes
                if !appState.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Búsquedas recientes")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(appState.recentSearches, id: \.self) { search in
                                    Button(action: {
                                        searchText = search
                                        performSearch(query: search)
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(search)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Sucursales Cercanas
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sucursales en \(appState.selectedLocation.city)")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(StoreBranch.defaultBranches) { branch in
                                branchCard(branch)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Espacio inferior
                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Hero Banner
    private var heroBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("¡Compara y ahorra!")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.primary)

                Text("Encontrá el precio más bajo en Bahía Blanca entre Vea, Carrefour, ChangoMás y La Coope.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .padding(.horizontal)
    }

    // MARK: - Branch Card
    private func branchCard(_ branch: StoreBranch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SupermarketBadge(branch.supermarket, style: .compact)
                Spacer()
                if branch.isOpen {
                    Text("ABIERTO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(branch.name)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(branch.address)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Label(String(format: "%.1f km", branch.distanceKm), systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Label(String(format: "%.1f", branch.rating), systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(14)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Filtro por supermercado
            supermarketFilterBar

            if isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Buscando mejores precios en los supermercados...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("No pudimos obtener los precios")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Reintentar") {
                        performSearch(query: searchText)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    Spacer()
                }
                .padding()
            } else if filteredResults.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No se encontraron productos")
                        .font(.headline)
                    Text("Intenta buscar con palabras clave más generales (ej: \"arroz\", \"aceite\", \"natura\").")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                List {
                    Section {
                        ForEach(filteredResults) { price in
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
                        }
                    } header: {
                        Text("\(filteredResults.count) resultados ordenados del más barato al más caro")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Supermarket Filter Bar
    private var supermarketFilterBar: some View {
        let stores = ["Todos", "Vea", "Carrefour", "ChangoMás", "Cooperativa Obrera"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stores, id: \.self) { store in
                    let isSelected = (store == "Todos" && selectedSupermarketFilter == nil) ||
                                     (selectedSupermarketFilter == store)
                    Button(action: {
                        if store == "Todos" {
                            selectedSupermarketFilter = nil
                        } else {
                            selectedSupermarketFilter = store
                        }
                    }) {
                        Text(store)
                            .font(.caption)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.green : Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var filteredResults: [SupermarketPrice] {
        guard let filter = selectedSupermarketFilter else {
            return searchResults
        }
        let lower = filter.lowercased()
        return searchResults.filter { $0.supermarket.localizedCaseInsensitiveContains(lower) }
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

    // MARK: - Search Action
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
}
