//
//  OffersView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct OffersView: View {
    @Environment(AppState.self) private var appState

    @State private var offers: [SupermarketPrice] = []
    @State private var isLoading = false
    @State private var selectedFilter: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtro horizontal
                filterBar

                if isLoading && offers.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Cargando ofertas del día...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if filteredOffers.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "tag.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No encontramos ofertas en este momento")
                            .font(.headline)
                        Text("Toca para volver a buscar o cambia de comercio.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Reintentar") {
                            loadOffers()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            ForEach(filteredOffers) { offer in
                                ProductSearchResultRow(price: offer) {
                                    appState.addToCart(
                                        productName: offer.productName ?? "Oferta",
                                        brand: offer.brand,
                                        imageUrl: offer.imageUrl,
                                        selectedPrice: offer,
                                        allPrices: [offer],
                                        quantity: 1,
                                        ean: offer.ean
                                    )
                                }
                            }
                        } header: {
                            Text("Promociones destacadas en \(appState.selectedLocation.city)")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await reloadOffers()
                    }
                }
            }
            .navigationTitle("Ofertas")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if offers.isEmpty {
                    loadOffers()
                }
            }
        }
    }

    private var filterBar: some View {
        let stores = ["Todos", "Vea", "Carrefour", "ChangoMás", "Cooperativa Obrera"]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stores, id: \.self) { store in
                    let isSelected = (store == "Todos" && selectedFilter == nil) || (selectedFilter == store)
                    Button(action: {
                        if store == "Todos" {
                            selectedFilter = nil
                        } else {
                            selectedFilter = store
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

    private var filteredOffers: [SupermarketPrice] {
        guard let filter = selectedFilter else { return offers }
        return offers.filter { $0.supermarket.localizedCaseInsensitiveContains(filter) }
    }

    private func loadOffers() {
        isLoading = true
        Task {
            let result = await PriceService.shared.fetchDailyOffers(location: appState.selectedLocation)
            await MainActor.run {
                self.offers = result
                self.isLoading = false
            }
        }
    }

    private func reloadOffers() async {
        let result = await PriceService.shared.fetchDailyOffers(location: appState.selectedLocation)
        await MainActor.run {
            self.offers = result
        }
    }
}
