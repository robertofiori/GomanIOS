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
            ZStack {
                // Fondo consistente con toda la app
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                Group {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Buscando las mejores ofertas en \(appState.selectedLocation.city)...")
                                .font(.montserrat(.semiBold, size: 14))
                                .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.62))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if offers.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            Image(systemName: "tag.slash")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            Text("No se encontraron ofertas disponibles en este momento.")
                                .font(.montserrat(.bold, size: 16))
                                .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                            Text("Probá cambiando la ubicación o intentá más tarde.")
                                .font(.montserrat(.regular, size: 14))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            Button("Reintentar") {
                                loadOffers()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
                            Spacer()
                        }
                        .padding()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Encabezado de la lista
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Promociones destacadas")
                                            .font(.montserrat(.black, size: 18))
                                            .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                                        Text("En \(appState.selectedLocation.city)")
                                            .font(.montserrat(.bold, size: 12))
                                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

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
                                .padding(.horizontal, 16)

                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .refreshable {
                            await reloadOffers()
                        }
                    }
                }
            }
            .navigationTitle("Ofertas del Día")
            .navigationBarTitleDisplayMode(.inline)
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
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
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
