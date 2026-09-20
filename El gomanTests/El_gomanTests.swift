//
//  El_gomanTests.swift
//  El gomanTests
//
//  Created by Roberto Fiori.
//

import Testing
import Foundation
@testable import El_goman

struct El_gomanTests {

    @Test func testPriceDecodingAndUnitParsing() async throws {
        let json = """
        {
            "id": "123",
            "name": "Vea",
            "price": 1500,
            "originalPrice": 1800,
            "isOffer": true,
            "inStock": true,
            "productName": "Aceite de Girasol 1.5 L"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(SupermarketPrice.self, from: json)
        #expect(item.supermarket == "Vea")
        #expect(item.price == 1500)
        #expect(item.isOffer == true)
        #expect(item.pricePerUnit == 1000) // 1500 / 1.5
        #expect(item.unitType == "$/lt")
    }

    @Test func testBasketOptimizerBestSupermarket() async throws {
        let veaPrice = SupermarketPrice(id: "1", supermarket: "Vea", price: 1000, inStock: true)
        let carrefourPrice = SupermarketPrice(id: "2", supermarket: "Carrefour", price: 1200, inStock: true)

        let cartItem = CartItem(
            productName: "Aceite",
            selectedPrice: veaPrice,
            allPrices: [veaPrice, carrefourPrice],
            quantity: 2
        )

        let result = BasketOptimizer.optimize(items: [cartItem], userBanks: [])
        #expect(result.bestSupermarket?.supermarket == "Vea")
        #expect(result.bestSupermarket?.effectiveTotal == 2000)
    }

    @Test func testBankDiscountApplicability() async throws {
        let discounts = BankDiscount.availableDiscounts
        #expect(discounts.count >= 4)
        #expect(discounts.contains(where: { $0.id == "cuentadni" }))
    }
}
