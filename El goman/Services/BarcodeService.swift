//
//  BarcodeService.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import Foundation

public actor BarcodeService {
    public static let shared = BarcodeService()

    private init() {}

    /// Busca la información nutricional / de producto en Open Food Facts
    public func fetchProductInfo(barcode: String) async -> ProductData? {
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBarcode.isEmpty,
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(cleanBarcode).json") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("ElMango-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            if result.status == 1, let p = result.product {
                return ProductData(
                    code: cleanBarcode,
                    productName: p.product_name,
                    imageUrl: p.image_url,
                    brands: p.brands,
                    quantity: p.quantity
                )
            }
            return nil
        } catch {
            return nil
        }
    }
}
