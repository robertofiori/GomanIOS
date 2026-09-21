//
//  ProductSearchResultRow.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct ProductSearchResultRow: View {
    let price: SupermarketPrice
    let isBestPrice: Bool
    let bestSavingsVsHighest: Double?
    let onAdd: (Int, Bool) -> Void // (quantity, isOptional)

    @State private var quantity: Int = 1
    @State private var addedAsPrincipal = false
    @State private var addedAsOptional = false

    public init(
        price: SupermarketPrice,
        isBestPrice: Bool = false,
        bestSavingsVsHighest: Double? = nil,
        onAdd: @escaping (Int, Bool) -> Void
    ) {
        self.price = price
        self.isBestPrice = isBestPrice
        self.bestSavingsVsHighest = bestSavingsVsHighest
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header con Badges
            HStack {
                SupermarketBadge(price.supermarket, style: .compact)

                if isBestPrice {
                    Text("MEJOR PRECIO")
                        .font(.montserrat(.black, size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.13, green: 0.77, blue: 0.36))
                        .clipShape(Capsule())
                }

                if price.isOffer == true || (price.originalPrice ?? 0) > price.price {
                    Text("OFERTA")
                        .font(.montserrat(.black, size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.98, green: 0.55, blue: 0.08)) // Naranja
                        .clipShape(Capsule())
                }

                if !price.inStock {
                    Text("SIN STOCK")
                        .font(.montserrat(.bold, size: 9))
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.93, green: 0.95, blue: 0.98))
                        .clipShape(Capsule())
                }

                Spacer()

                // Botón "Ver en tienda" con link
                if let urlString = price.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                            Text("Ver en tienda")
                                .font(.montserrat(.bold, size: 10))
                        }
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }
                }
            }
            .padding(.bottom, 10)

            // Contenido Principal: Imagen + Nombre + Precios
            HStack(alignment: .top, spacing: 14) {
                // Imagen con fondo blanco redondeado
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                    if let imageUrl = price.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 68, height: 68)
                            case .failure:
                                Image(systemName: "basket.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0.80, green: 0.84, blue: 0.90))
                            case .empty:
                                ProgressView()
                                    .scaleEffect(0.8)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "basket.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.80, green: 0.84, blue: 0.90))
                    }
                }

                // Info de Producto
                VStack(alignment: .leading, spacing: 4) {
                    Text(price.productName ?? "Producto")
                        .font(.montserrat(.bold, size: 14))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .lineLimit(2)

                    if let brand = price.brand, !brand.isEmpty {
                        Text(brand.uppercased())
                            .font(.montserrat(.bold, size: 10))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    }

                    // Precio y Original / Ahorro
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formatPrice(price.price))
                            .font(.montserrat(.black, size: 20))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))

                        if let orig = price.originalPrice, orig > price.price {
                            Text(formatPrice(orig))
                                .font(.montserrat(.semiBold, size: 13))
                                .strikethrough(true, color: Color(red: 0.58, green: 0.64, blue: 0.72))
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        }
                    }

                    // Precio por Unidad de Referencia (Kg / L / U)
                    if let ppu = price.pricePerUnit, let uLabel = price.unitType {
                        HStack(spacing: 3) {
                            Text("⚖️")
                                .font(.system(size: 11))
                            Text("\(formatPrice(ppu)) / \(uLabel)")
                                .font(.montserrat(.bold, size: 11))
                                .foregroundColor(Color(red: 0.13, green: 0.65, blue: 0.35))
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            Divider()
                .padding(.vertical, 12)

            // Fila Inferior: Selector de Cantidad (- / +) + Botones AGREGAR y OPCIONAL
            HStack(spacing: 10) {
                // Stepper de Cantidad (- 1 +)
                HStack(spacing: 10) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if quantity > 1 { quantity -= 1 }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(quantity > 1 ? Color(red: 0.08, green: 0.12, blue: 0.18) : Color(red: 0.78, green: 0.82, blue: 0.88))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(quantity <= 1)

                    Text("\(quantity)")
                        .font(.montserrat(.black, size: 15))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .frame(minWidth: 20)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if quantity < 99 { quantity += 1 }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(red: 0.94, green: 0.96, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Botón OPCIONAL (Color Rosa/Magenta similar al botón "HACER OPCIONAL" de las capturas)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAdd(quantity, true)
                    withAnimation {
                        addedAsOptional = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        addedAsOptional = false
                    }
                }) {
                    HStack(spacing: 4) {
                        if addedAsOptional {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                        }
                        Text(addedAsOptional ? "LISTO" : "OPCIONAL")
                            .font(.montserrat(.black, size: 11))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color(red: 0.93, green: 0.12, blue: 0.47)) // Magenta #EC4899 / #E11D48
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                // Botón AGREGAR (Principal Verde)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAdd(quantity, false)
                    withAnimation {
                        addedAsPrincipal = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        addedAsPrincipal = false
                    }
                }) {
                    HStack(spacing: 4) {
                        if addedAsPrincipal {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                        }
                        Text(addedAsPrincipal ? "AGREGADO" : "AGREGAR")
                            .font(.montserrat(.black, size: 12))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color(red: 0.13, green: 0.77, blue: 0.36)) // Verde principal
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(red: 0.13, green: 0.77, blue: 0.36).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_AR")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
