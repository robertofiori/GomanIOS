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
    private let cacheTTL: TimeInterval = 600 // 10 minutos

    private init() {}

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

        // Filtrar cadenas y supermercados según la localidad
        var validPrices = rawPrices.filter { item in
            let lowerSM = item.supermarket.lowercased()
            // Excluir DIA si aplica como en la web
            if lowerSM.contains("dia") { return false }
            return true
        }

        if location.city.localizedCaseInsensitiveContains("Bahía Blanca") || location.city.localizedCaseInsensitiveContains("Bahia Blanca") {
            let allowed = ["vea", "carrefour", "chango mas", "cooperativa obrera", "la coope"]
            validPrices = validPrices.filter { item in
                let lower = item.supermarket.lowercased()
                return allowed.some(where: { lower.contains($0) })
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
                let offers = prices.filter { ($0.isOffer == true || ($0.originalPrice ?? 0) > $0.price) && $0.inStock && $0.price > 0 && ($0.imageUrl != nil && !$0.imageUrl!.isEmpty) }
                allOffers.append(contentsOf: offers)
            }

            // Deduplicar por nombre y supermercado
            var unique: [SupermarketPrice] = []
            var seen = Set<String>()
            for item in allOffers {
                let key = "\(item.productName?.prefix(25).lowercased() ?? "")_\(item.supermarket.lowercased())"
                if !seen.contains(key) {
                    seen.insert(key)
                    unique.append(item)
                }
            }

            return Array(unique.shuffled().prefix(12))
        }
    }
}

private extension Array {
    func some(where predicate: (Element) -> Bool) -> Bool {
        contains(where: predicate)
    }
}
