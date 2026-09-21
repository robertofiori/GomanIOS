//
//  ProductModels.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import Foundation

// MARK: - Guided Search / Suggestions Response
public struct ProductSuggestion: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let brand: String?
    public let imageUrl: String?
    public let ean: String?

    public init(id: String = UUID().uuidString, name: String, brand: String? = nil, imageUrl: String? = nil, ean: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageUrl = imageUrl
        self.ean = ean
    }
}

public struct GuidedSearchResponse: Codable, Sendable {
    public let products: [ProductSuggestion]?
    public let types: [String]?
    public let sizes: [String]?
}

// MARK: - Supermarket Price Item
public struct SupermarketPrice: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let supermarket: String
    public let price: Double
    public let originalPrice: Double?
    public let isOffer: Bool?
    public let inStock: Bool
    public let url: String?
    public let imageUrl: String?
    public let productName: String?
    public let brand: String?
    public let pricePerUnit: Double?
    public let unitType: String?
    public let ean: String?

    public init(
        id: String,
        supermarket: String,
        price: Double,
        originalPrice: Double? = nil,
        isOffer: Bool? = nil,
        inStock: Bool = true,
        url: String? = nil,
        imageUrl: String? = nil,
        productName: String? = nil,
        brand: String? = nil,
        pricePerUnit: Double? = nil,
        unitType: String? = nil,
        ean: String? = nil
    ) {
        self.id = id
        self.supermarket = supermarket
        self.price = price
        self.originalPrice = originalPrice
        self.isOffer = isOffer
        self.inStock = inStock
        self.url = url
        self.imageUrl = imageUrl
        self.productName = productName
        self.brand = brand
        self.pricePerUnit = pricePerUnit
        self.unitType = unitType
        self.ean = ean
    }

    enum CodingKeys: String, CodingKey {
        case id
        case supermarket = "name"
        case price
        case originalPrice
        case isOffer
        case inStock
        case url
        case imageUrl
        case productName
        case brand
        case ean
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawId = try? container.decode(String.self, forKey: .id)
        let name = (try? container.decode(String.self, forKey: .supermarket)) ?? "Supermercado"
        self.supermarket = name
        self.id = (rawId != nil && !rawId!.isEmpty) ? rawId! : UUID().uuidString
        
        self.price = (try? container.decode(Double.self, forKey: .price)) ?? 0
        self.originalPrice = try? container.decodeIfPresent(Double.self, forKey: .originalPrice)
        self.isOffer = try? container.decodeIfPresent(Bool.self, forKey: .isOffer)
        self.inStock = (try? container.decode(Bool.self, forKey: .inStock)) ?? true
        self.url = try? container.decodeIfPresent(String.self, forKey: .url)
        self.imageUrl = try? container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.productName = try? container.decodeIfPresent(String.self, forKey: .productName)
        self.brand = try? container.decodeIfPresent(String.self, forKey: .brand)
        self.ean = try? container.decodeIfPresent(String.self, forKey: .ean)
        
        // Calcular precio por unidad si es posible
        if let pName = self.productName, self.price > 0 {
            let unitInfo = ProductModelsHelper.parseUnit(from: pName, price: self.price)
            self.pricePerUnit = unitInfo.pricePerUnit
            self.unitType = unitInfo.unitLabel
        } else {
            self.pricePerUnit = nil
            self.unitType = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(supermarket, forKey: .supermarket)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(originalPrice, forKey: .originalPrice)
        try container.encodeIfPresent(isOffer, forKey: .isOffer)
        try container.encode(inStock, forKey: .inStock)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(ean, forKey: .ean)
    }
}

// MARK: - Open Food Facts Product Data
public struct ProductData: Identifiable, Codable, Hashable, Sendable {
    public var id: String { code }
    public let code: String
    public let productName: String?
    public let imageUrl: String?
    public let brands: String?
    public let quantity: String?

    public init(
        code: String,
        productName: String? = nil,
        imageUrl: String? = nil,
        brands: String? = nil,
        quantity: String? = nil
    ) {
        self.code = code
        self.productName = productName
        self.imageUrl = imageUrl
        self.brands = brands
        self.quantity = quantity
    }
}

// MARK: - Open Food Facts Response DTO
struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?

    struct OpenFoodFactsProduct: Decodable {
        let product_name: String?
        let image_url: String?
        let brands: String?
        let quantity: String?
    }
}

// MARK: - Shopping Cart Item
public struct CartItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var productName: String
    public var brand: String?
    public var imageUrl: String?
    public var selectedPrice: SupermarketPrice
    public var allPrices: [SupermarketPrice]
    public var quantity: Int
    public var isChecked: Bool
    public var isOptional: Bool
    public var ean: String?

    public init(
        id: UUID = UUID(),
        productName: String,
        brand: String? = nil,
        imageUrl: String? = nil,
        selectedPrice: SupermarketPrice,
        allPrices: [SupermarketPrice] = [],
        quantity: Int = 1,
        isChecked: Bool = false,
        isOptional: Bool = false,
        ean: String? = nil
    ) {
        self.id = id
        self.productName = productName
        self.brand = brand
        self.imageUrl = imageUrl
        self.selectedPrice = selectedPrice
        self.allPrices = allPrices.isEmpty ? [selectedPrice] : allPrices
        self.quantity = quantity
        self.isChecked = isChecked
        self.isOptional = isOptional
        self.ean = ean
    }

    public var totalCost: Double {
        selectedPrice.price * Double(quantity)
    }
}

// MARK: - Location Data
public struct LocationData: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let city: String
    public let province: String
    public let zipCode: String

    public init(id: String, city: String, province: String, zipCode: String) {
        self.id = id
        self.city = city
        self.province = province
        self.zipCode = zipCode
    }

    public static let bahiaBlanca = LocationData(
        id: "bahiablanca",
        city: "Bahía Blanca",
        province: "Buenos Aires",
        zipCode: "8000"
    )

    public static let availableLocations: [LocationData] = [
        .bahiaBlanca,
        LocationData(id: "caba", city: "CABA", province: "Buenos Aires", zipCode: "1000"),
        LocationData(id: "laplata", city: "La Plata", province: "Buenos Aires", zipCode: "1900"),
        LocationData(id: "mardelplata", city: "Mar del Plata", province: "Buenos Aires", zipCode: "7600"),
        LocationData(id: "cordoba", city: "Córdoba", province: "Córdoba", zipCode: "5000"),
        LocationData(id: "rosario", city: "Rosario", province: "Santa Fe", zipCode: "2000")
    ]
}

// MARK: - Store / Branch
public struct StoreBranch: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let supermarket: String
    public let address: String
    public let distanceKm: Double
    public let rating: Double
    public let isOpen: Bool
    public let systemImage: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        supermarket: String,
        address: String,
        distanceKm: Double,
        rating: Double,
        isOpen: Bool,
        systemImage: String = "cart.fill"
    ) {
        self.id = id
        self.name = name
        self.supermarket = supermarket
        self.address = address
        self.distanceKm = distanceKm
        self.rating = rating
        self.isOpen = isOpen
        self.systemImage = systemImage
    }

    public static let defaultBranches: [StoreBranch] = [
        StoreBranch(name: "Vea - Centro", supermarket: "Vea", address: "Alsina 150", distanceKm: 0.6, rating: 4.5, isOpen: true),
        StoreBranch(name: "Carrefour Hiper", supermarket: "Carrefour", address: "Av. Cabrera 4114", distanceKm: 3.2, rating: 4.8, isOpen: true),
        StoreBranch(name: "Cooperativa Obrera 28", supermarket: "Cooperativa Obrera", address: "Belgrano 45", distanceKm: 0.8, rating: 4.7, isOpen: true),
        StoreBranch(name: "ChangoMás", supermarket: "Chango Más", address: "Av. Colón 450", distanceKm: 1.4, rating: 4.3, isOpen: true)
    ]
}

// MARK: - Unit Parser Helper
public enum ProductModelsHelper {
    public static func parseUnit(from title: String, price: Double) -> (pricePerUnit: Double?, unitLabel: String?) {
        let pattern = #"(?i)(\d+(?:[.,]\d+)?)\s*(kg|kilos?|g|gr|gramos?|l|lt|litros?|ml|cc)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (nil, nil)
        }
        let range = NSRange(title.startIndex..<title.endIndex, in: title)
        guard let match = regex.firstMatch(in: title, options: [], range: range) else {
            return (nil, nil)
        }

        guard let amountRange = Range(match.range(at: 1), in: title),
              let unitRange = Range(match.range(at: 2), in: title) else {
            return (nil, nil)
        }

        let amountStr = String(title[amountRange]).replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(amountStr), amount > 0 else { return (nil, nil) }
        let unit = String(title[unitRange]).lowercased()

        if ["kg", "kilo", "kilos"].contains(unit) {
            return (price / amount, "Kg")
        } else if ["g", "gr", "gramos"].contains(unit) {
            let kg = amount / 1000.0
            return (price / kg, "Kg")
        } else if ["l", "lt", "litros", "litro"].contains(unit) {
            return (price / amount, "L")
        } else if ["ml", "cc"].contains(unit) {
            let lt = amount / 1000.0
            return (price / lt, "L")
        }

        return (nil, nil)
    }
}
