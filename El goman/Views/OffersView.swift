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
    @State private var isLoading = true
    @State private var selectedFilter: String? = nil

    public init() {}

    private var supermarkets: [String] {
        let all = offers.map { $0.supermarket }
        return Array(Set(all)).sorted()
    }

    private var filteredOffers: [SupermarketPrice] {
        guard let selected = selectedFilter else { return offers }
        return offers.filter { $0.supermarket == selected }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Buscando las mejores ofertas en \(appState.selectedLocation.city)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if offers.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "tag.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No se encontraron ofertas disponibles en este momento.")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Probá cambiando la ubicación o intentá más tarde.")
                            .font(.subheadline)
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
                                ProductSearchResultRow(
                                    price: offer,
                                    isBestPrice: false,
                                    bestSavingsVsHighest: nil
                                ) { qty, isOptional in
                                    appState.addToCart(
                                        productName: offer.productName ?? "Oferta",
                                        brand: offer.brand,
                                        imageUrl: offer.imageUrl,
                                        selectedPrice: offer,
                                        allPrices: [offer],
                                        quantity: qty,
                                        isOptional: isOptional,
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
            .navigationTitle("Ofertas del Día")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !supermarkets.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Todos") {
                                selectedFilter = nil
                            }
                            ForEach(supermarkets, id: \.self) { sm in
                                Button(sm) {
                                    selectedFilter = sm
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .symbolVariant(selectedFilter == nil ? .none : .fill)
                        }
                    }
                }
            }
            .task {
                if offers.isEmpty {
                    loadOffers()
                }
            }
        }
    }

    private func loadOffers() {
        isLoading = true
        Task {
            let fetched = await PriceService.shared.fetchDailyOffers(location: appState.selectedLocation)
            await MainActor.run {
                self.offers = fetched
                self.isLoading = false
            }
        }
    }

    private func reloadOffers() async {
        let fetched = await PriceService.shared.fetchDailyOffers(location: appState.selectedLocation)
        await MainActor.run {
            self.offers = fetched
        }
    }
}
