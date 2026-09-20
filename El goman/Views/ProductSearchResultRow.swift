//
//  ProductSearchResultRow.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct ProductSearchResultRow: View {
    let price: SupermarketPrice
    let onAdd: () -> Void

    @State private var isAdded = false

    public init(price: SupermarketPrice, onAdd: @escaping () -> Void) {
        self.price = price
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Imagen del producto
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 72, height: 72)

                if let imageUrl = price.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "basket.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.8)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "basket.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            // Datos del producto
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    SupermarketBadge(price.supermarket, style: .compact)
                    
                    if price.isOffer == true || (price.originalPrice ?? 0) > price.price {
                        Text("OFERTA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }

                    if !price.inStock {
                        Text("SIN STOCK")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }

                Text(price.productName ?? "Producto")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let brand = price.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatPrice(price.price))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.green)

                    if let orig = price.originalPrice, orig > price.price {
                        Text(formatPrice(orig))
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }

                    if let ppu = price.pricePerUnit, let uLabel = price.unitType {
                        Text("(\(formatPrice(ppu)) \(uLabel))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer(minLength: 4)

            // Botón de agregar a la lista
            Button(action: {
                onAdd()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAdded = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation {
                        isAdded = false
                    }
                }
            }) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isAdded ? .green : .accentColor)
                    .symbolEffect(.bounce, value: isAdded)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 6)
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
