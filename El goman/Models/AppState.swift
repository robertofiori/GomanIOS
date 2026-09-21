//
//  AppState.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI
import Observation

@Observable
public final class AppState {
    public var isDarkMode: Bool = false {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "is_dark_mode_preference")
        }
    }

    public var cartItems: [CartItem] = [] {
        didSet {
            saveCart()
        }
    }

    public var selectedLocation: LocationData = .bahiaBlanca {
        didSet {
            saveLocation()
        }
    }

    public var selectedBanks: Set<String> = ["cuentadni"] {
        didSet {
            saveBanks()
        }
    }

    public var recentSearches: [String] = ["Aceite Natura", "Leche La Serenísima", "Arroz Gallo", "Fideos Matarazzo"] {
        didSet {
            saveRecentSearches()
        }
    }

    private let cartKey = "saved_cart_items_v2"
    private let locationKey = "saved_location_v1"
    private let banksKey = "saved_banks_v1"
    private let searchesKey = "saved_searches_v1"

    public init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "is_dark_mode_preference")
        loadData()
    }

    public func toggleTheme() {
        isDarkMode.toggle()
    }

    // MARK: - Cart Actions
    public func addToCart(
        productName: String,
        brand: String? = nil,
        imageUrl: String? = nil,
        selectedPrice: SupermarketPrice,
        allPrices: [SupermarketPrice] = [],
        quantity: Int = 1,
        isOptional: Bool = false,
        ean: String? = nil
    ) {
        if let index = cartItems.firstIndex(where: {
            $0.productName.localizedCaseInsensitiveCompare(productName) == .orderedSame &&
            $0.selectedPrice.supermarket == selectedPrice.supermarket &&
            $0.isOptional == isOptional
        }) {
            cartItems[index].quantity += quantity
        } else {
            let newItem = CartItem(
                productName: productName,
                brand: brand,
                imageUrl: imageUrl,
                selectedPrice: selectedPrice,
                allPrices: allPrices.isEmpty ? [selectedPrice] : allPrices,
                quantity: quantity,
                isChecked: false,
                isOptional: isOptional,
                ean: ean
            )
            cartItems.append(newItem)
        }
    }

    public func addToCart(_ price: SupermarketPrice, quantity: Int = 1, isOptional: Bool = false) {
        addToCart(
            productName: price.productName ?? "Producto",
            brand: price.brand,
            imageUrl: price.imageUrl,
            selectedPrice: price,
            allPrices: [price],
            quantity: quantity,
            isOptional: isOptional,
            ean: price.ean
        )
    }

    public func updateQuantity(for item: CartItem, delta: Int) {
        guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        let newQuantity = cartItems[index].quantity + delta
        if newQuantity > 0 {
            cartItems[index].quantity = newQuantity
        } else {
            cartItems.remove(at: index)
        }
    }

    public func setQuantity(for item: CartItem, quantity: Int) {
        guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity > 0 {
            cartItems[index].quantity = min(quantity, 99)
        } else {
            cartItems.remove(at: index)
        }
    }

    public func toggleOptional(for item: CartItem) {
        guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        cartItems[index].isOptional.toggle()
    }

    public func replacePrice(for itemId: UUID, with newPrice: SupermarketPrice) {
        guard let index = cartItems.firstIndex(where: { $0.id == itemId }) else { return }
        cartItems[index].selectedPrice = newPrice
    }

    public func removeItem(withId id: UUID) {
        cartItems.removeAll(where: { $0.id == id })
    }

    public func toggleItemCheck(withId id: UUID) {
        if let index = cartItems.firstIndex(where: { $0.id == id }) {
            cartItems[index].isChecked.toggle()
        }
    }

    public func clearCart() {
        cartItems.removeAll()
    }

    public var totalCartUnitsCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    public var currentCartTotal: Double {
        cartItems.reduce(0.0) { $0 + $1.totalCost }
    }

    public var optimizationResults: OptimizationResults {
        BasketOptimizer.optimize(items: cartItems, userBanks: selectedBanks)
    }

    public func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var list = recentSearches.filter { $0.localizedCaseInsensitiveCompare(trimmed) != .orderedSame }
        list.insert(trimmed, at: 0)
        recentSearches = Array(list.prefix(8))
    }

    public func toggleBank(_ bankId: String) {
        if selectedBanks.contains(bankId) {
            selectedBanks.remove(bankId)
        } else {
            selectedBanks.insert(bankId)
        }
    }

    // MARK: - Persistence
    private func saveCart() {
        if let encoded = try? JSONEncoder().encode(cartItems) {
            UserDefaults.standard.set(encoded, forKey: cartKey)
        }
    }

    private func saveLocation() {
        if let encoded = try? JSONEncoder().encode(selectedLocation) {
            UserDefaults.standard.set(encoded, forKey: locationKey)
        }
    }

    private func saveBanks() {
        let array = Array(selectedBanks)
        UserDefaults.standard.set(array, forKey: banksKey)
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: searchesKey)
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: cartKey),
           let items = try? JSONDecoder().decode([CartItem].self, from: data) {
            self.cartItems = items
        }
        if let data = UserDefaults.standard.data(forKey: locationKey),
           let loc = try? JSONDecoder().decode(LocationData.self, from: data) {
            self.selectedLocation = loc
        }
        if let banks = UserDefaults.standard.stringArray(forKey: banksKey) {
            self.selectedBanks = Set(banks)
        }
        if let searches = UserDefaults.standard.stringArray(forKey: searchesKey) {
            self.recentSearches = searches
        }
    }
}
