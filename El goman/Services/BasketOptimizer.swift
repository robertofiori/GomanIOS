//
//  BasketOptimizer.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import Foundation
import SwiftUI

// MARK: - Bank Discount Model
public struct BankDiscount: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let discount: Double // 0.3 for 30%
    public let cap: Double? // Maximum savings
    public let days: [Int] // 1 = Sunday, 2 = Monday, 3 = Tuesday, etc. (Calendar.current.component(.weekday))
    public let supermarkets: [String] // lowercase
    public let color: Color

    public init(
        id: String,
        name: String,
        discount: Double,
        cap: Double? = nil,
        days: [Int],
        supermarkets: [String],
        color: Color
    ) {
        self.id = id
        self.name = name
        self.discount = discount
        self.cap = cap
        self.days = days
        self.supermarkets = supermarkets
        self.color = color
    }

    public static let availableDiscounts: [BankDiscount] = [
        BankDiscount(
            id: "cuentadni",
            name: "Cuenta DNI",
            discount: 0.30,
            cap: 4000,
            days: [2, 3], // Lunes y Martes
            supermarkets: ["vea", "carrefour", "chango mas", "cooperativa obrera", "la coope"],
            color: Color(red: 0, green: 173/255, blue: 239/255)
        ),
        BankDiscount(
            id: "bnaplus",
            name: "BNA+ (Nación)",
            discount: 0.35,
            cap: 5000,
            days: [4, 5], // Miércoles y Jueves
            supermarkets: ["carrefour", "vea", "chango mas"],
            color: Color(red: 0, green: 74/255, blue: 142/255)
        ),
        BankDiscount(
            id: "modosantafe",
            name: "MODO (Macro / Nación)",
            discount: 0.20,
            cap: 2500,
            days: [2, 3, 4, 5, 6], // Lunes a Viernes
            supermarkets: ["cooperativa obrera", "la coope"],
            color: Color(red: 236/255, green: 28/255, blue: 36/255)
        ),
        BankDiscount(
            id: "personalpay",
            name: "Personal Pay",
            discount: 0.15,
            cap: 2000,
            days: [1, 2, 3, 4, 5, 6, 7], // Todos los días
            supermarkets: ["vea", "carrefour", "chango mas"],
            color: Color(red: 1/255, green: 254/255, blue: 156/255)
        )
    ]

    public static func getApplicableDiscount(for supermarket: String, userBanks: Set<String>) -> BankDiscount? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let lowerSM = supermarket.lowercased()

        let valid = availableDiscounts.filter { discount in
            userBanks.contains(discount.id) &&
            discount.days.contains(weekday) &&
            discount.supermarkets.contains(where: { lowerSM.contains($0) })
        }

        return valid.max(by: { $0.discount < $1.discount })
    }
}

// MARK: - Optimization Results
public struct SupermarketBasketTotal: Identifiable, Hashable, Sendable {
    public var id: String { supermarket }
    public let supermarket: String
    public let effectiveTotal: Double
    public let rawTotal: Double
    public let itemCount: Int
    public let missingItems: Int
    public let matchPercentage: Int
    public let appliedDiscount: String?
    public let savingsVsCurrent: Double
}

public struct OptimizationResults: Sendable {
    public let totalsPerSupermarket: [SupermarketBasketTotal]
    public let theoreticalMin: Double
    public let currentTotal: Double
    public let bestSupermarket: SupermarketBasketTotal?
}

// MARK: - Basket Optimizer Engine
public enum BasketOptimizer {
    public static func optimize(items: [CartItem], userBanks: Set<String> = []) -> OptimizationResults {
        guard !items.isEmpty else {
            return OptimizationResults(
                totalsPerSupermarket: [],
                theoreticalMin: 0,
                currentTotal: 0,
                bestSupermarket: nil
            )
        }

        var allSupermarkets = Set<String>()
        for item in items {
            for price in item.allPrices {
                allSupermarkets.insert(price.supermarket)
            }
            allSupermarkets.insert(item.selectedPrice.supermarket)
        }

        let currentTotal = items.reduce(0.0) { $0 + ($1.selectedPrice.price * Double($1.quantity)) }

        var totals: [SupermarketBasketTotal] = []

        for sm in allSupermarkets {
            var rawTotal = 0.0
            var itemCount = 0
            var missingItems = 0

            for item in items {
                if let priceInSm = item.allPrices.first(where: { $0.supermarket.localizedCaseInsensitiveContains(sm) && $0.inStock && $0.price > 0 }) {
                    rawTotal += priceInSm.price * Double(item.quantity)
                    itemCount += 1
                } else if item.selectedPrice.supermarket.localizedCaseInsensitiveContains(sm) {
                    rawTotal += item.selectedPrice.price * Double(item.quantity)
                    itemCount += 1
                } else {
                    // Si no está disponible en este súper, estimar con el promedio de otros supermercados
                    let validPrices = item.allPrices.filter { $0.inStock && $0.price > 0 }
                    let avgPrice = !validPrices.isEmpty
                        ? validPrices.reduce(0.0) { $0 + $1.price } / Double(validPrices.count)
                        : item.selectedPrice.price
                    rawTotal += avgPrice * Double(item.quantity)
                    missingItems += 1
                }
            }

            let matchPercentage = Int(round((Double(itemCount) / Double(items.count)) * 100))
            let discountInfo = BankDiscount.getApplicableDiscount(for: sm, userBanks: userBanks)

            let effectiveTotal: Double
            if let disc = discountInfo {
                let saving = rawTotal * disc.discount
                let cappedSaving = disc.cap != nil ? min(saving, disc.cap!) : saving
                effectiveTotal = max(0, rawTotal - cappedSaving)
            } else {
                effectiveTotal = rawTotal
            }

            let savingsVsCurrent = currentTotal - effectiveTotal

            totals.append(SupermarketBasketTotal(
                supermarket: sm,
                effectiveTotal: effectiveTotal,
                rawTotal: rawTotal,
                itemCount: itemCount,
                missingItems: missingItems,
                matchPercentage: matchPercentage,
                appliedDiscount: discountInfo?.name,
                savingsVsCurrent: savingsVsCurrent
            ))
        }

        totals.sort { $0.effectiveTotal < $1.effectiveTotal }

        // Mínimo teórico: comprar cada producto individual en su lugar más barato
        let theoreticalMin = items.reduce(0.0) { sum, item in
            let validPrices = item.allPrices.filter { $0.inStock && $0.price > 0 }
            let bestPrice = !validPrices.isEmpty
                ? min(validPrices.map(\.price).min() ?? item.selectedPrice.price, item.selectedPrice.price)
                : item.selectedPrice.price
            return sum + (bestPrice * Double(item.quantity))
        }

        return OptimizationResults(
            totalsPerSupermarket: totals,
            theoreticalMin: theoreticalMin,
            currentTotal: currentTotal,
            bestSupermarket: totals.first
        )
    }
}
