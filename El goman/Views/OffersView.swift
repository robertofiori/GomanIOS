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
        var list = ["Carrefour", "Chango Más", "Cooperativa Obrera", "VEA"]
        for offer in offers {
            let sm = offer.supermarket
            let norm = sm.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
            if !list.contains(where: { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased() == norm }) {
                list.append(sm)
            }
        }
        return list.sorted()
    }

    private var filteredOffers: [SupermarketPrice] {
        guard let selected = selectedFilter else { return offers }
        func normalize(_ str: String) -> String {
            str.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let normSelected = normalize(selected)
        return offers.filter { offer in
            let normSM = normalize(offer.supermarket)
            if normSelected.contains("chango") || normSelected.contains("masonline") {
                return normSM.contains("chango") || normSM.contains("masonline")
            }
            if normSelected.contains("coope") {
                return normSM.contains("coop")
            }
            if normSelected.contains("carrefour") {
                return normSM.contains("carrefour")
            }
            if normSelected.contains("vea") {
                return normSM.contains("vea")
            }
            return normSM.contains(normSelected) || normSelected.contains(normSM)
        }
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
                    } else if offers.isEmpty || filteredOffers.isEmpty {
                        VStack(spacing: 14) {
                            Spacer()
                            Image(systemName: "tag.slash")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            Text(selectedFilter == nil ? "No se encontraron ofertas disponibles en este momento." : "No se encontraron ofertas para \(selectedFilter!)")
                                .font(.montserrat(.bold, size: 16))
                                .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                                .multilineTextAlignment(.center)
                            Text("Probá cambiando el filtro o intentá más tarde.")
                                .font(.montserrat(.regular, size: 14))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                            if selectedFilter != nil {
                                Button("Ver todas las ofertas") {
                                    selectedFilter = nil
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
                            } else {
                                Button("Reintentar") {
                                    loadOffers()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
                            }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedFilter = nil
                        }) {
                            if selectedFilter == nil {
                                Label("Todos", systemImage: "checkmark")
                            } else {
                                Text("Todos")
                            }
                        }

                        Divider()

                        ForEach(supermarkets, id: \.self) { sm in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedFilter = sm
                            }) {
                                if selectedFilter == sm {
                                    Label(sm, systemImage: "checkmark")
                                } else {
                                    Text(sm)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
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
