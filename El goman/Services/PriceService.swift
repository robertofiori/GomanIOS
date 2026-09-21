//
//  PriceService.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import Foundation

public actor PriceService {
    public static let shared = PriceService()

    private var cache: [String: (data: [SupermarketPrice], timestamp: Date)] = [:]
    private var suggestionsCache: [String: [ProductSuggestion]] = [:]
    private let cacheTTL: TimeInterval = 600 // 10 minutos

    private init() {}

    // MARK: - Autocompletado de sugerencias en vivo
    public func fetchSuggestions(query: String) async -> [ProductSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let cacheKey = trimmed.lowercased()
        if let cached = suggestionsCache[cacheKey] {
            return cached
        }

        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://getsearchsuggestions-4glajx37za-uc.a.run.app?q=\(encoded)") else {
            return []
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return []
            }
            let res = try JSONDecoder().decode(GuidedSearchResponse.self, from: data)
            let suggestions = res.products ?? []
            suggestionsCache[cacheKey] = suggestions
            return suggestions
        } catch {
            return []
        }
    }

    public func searchPrices(
        query: String,
        location: LocationData = .bahiaBlanca
    ) async throws -> [SupermarketPrice] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let cacheKey = "\(trimmedQuery.lowercased())_\(location.city.lowercased())"
        if let cached = cache[cacheKey], Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.data
        }

        guard var components = URLComponents(string: "https://getsupermarketprices-4glajx37za-uc.a.run.app") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: trimmedQuery),
            URLQueryItem(name: "zipCode", value: location.zipCode),
            URLQueryItem(name: "city", value: location.city)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let rawPrices = try decoder.decode([SupermarketPrice].self, from: data)

        // Helper para normalizar cadenas quitando acentos y diacríticos
        func normalizeStr(_ str: String) -> String {
            str.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Filtrar cadenas y supermercados según la localidad
        var validPrices = rawPrices.filter { item in
            let normSM = normalizeStr(item.supermarket)
            // Excluir DIA si aplica como en la web
            if normSM.contains("dia") { return false }
            return true
        }

        let normCity = normalizeStr(location.city)
        if normCity.contains("bahia blanca") {
            let allowed = [
                "vea",
                "carrefour",
                "chango mas",
                "chango más",
                "changomas",
                "masonline",
                "cooperativa obrera",
                "la coope"
            ].map(normalizeStr)

            validPrices = validPrices.filter { item in
                let normSM = normalizeStr(item.supermarket)
                return allowed.contains { allowedItem in
                    normSM.contains(allowedItem) || allowedItem.contains(normSM)
                }
            }
        }

        // Ordenar: En stock y precio > 0 primero, de menor a mayor precio
        let sorted = validPrices.sorted { a, b in
            if a.inStock && a.price > 0 && (!b.inStock || b.price == 0) { return true }
            if b.inStock && b.price > 0 && (!a.inStock || a.price == 0) { return false }
            return a.price < b.price
        }

        cache[cacheKey] = (data: sorted, timestamp: Date())
        return sorted
    }

    public func fetchDailyOffers(location: LocationData = .bahiaBlanca) async -> [SupermarketPrice] {
        let categories = ["aceite", "leche", "arroz", "fideos", "limpieza"]

        return await withTaskGroup(of: [SupermarketPrice].self) { group in
            for category in categories {
                group.addTask {
                    do {
                        return try await self.searchPrices(query: category, location: location)
                    } catch {
                        return []
                    }
                }
            }

            var allOffers: [SupermarketPrice] = []
            for await prices in group {
                // Ofertas explícitas
                let explicitOffers = prices.filter { ($0.isOffer == true || ($0.originalPrice ?? 0) > $0.price) && $0.inStock && $0.price > 0 && ($0.imageUrl != nil && !$0.imageUrl!.isEmpty) }
                allOffers.append(contentsOf: explicitOffers)

                // Incluir productos destacados de Chango Más / Masonline para que tengan presencia en ofertas
                let changoItems = prices.filter { item in
                    let norm = item.supermarket.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
                    let isChango = norm.contains("chango") || norm.contains("masonline")
                    return isChango && item.inStock && item.price > 0 && (item.imageUrl != nil && !item.imageUrl!.isEmpty)
                }
                let changoOffers = changoItems.prefix(3).map { item in
                    SupermarketPrice(
                        id: item.id,
                        supermarket: "Chango Más",
                        price: item.price,
                        originalPrice: item.originalPrice ?? (item.price * 1.12),
                        isOffer: true,
                        inStock: item.inStock,
                        url: item.url,
                        imageUrl: item.imageUrl,
                        productName: item.productName,
                        brand: item.brand,
                        pricePerUnit: item.pricePerUnit,
                        unitType: item.unitType,
                        ean: item.ean
                    )
                }
                allOffers.append(contentsOf: changoOffers)
            }

            var uniqueMap = [String: SupermarketPrice]()
            for item in allOffers {
                let pKey = String((item.productName?.lowercased() ?? item.id).prefix(20))
                let smKey = item.supermarket.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
                let key = "\(pKey)-\(smKey)"
                if uniqueMap[key] == nil {
                    uniqueMap[key] = item
                }
            }
            return Array(uniqueMap.values).sorted(by: { $0.price < $1.price })
        }
    }
}
