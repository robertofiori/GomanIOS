//
//  CartView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct CartView: View {
    @Environment(AppState.self) private var appState
    @State private var showClearConfirmation = false
    @State private var isChanguitoMode = false
    @State private var showShareSheet = false
    @State private var shareText: String = ""

    public init() {}

    // Agrupar items por supermercado (como VEA, CARREFOUR, etc. en List 1.PNG)
    private var groupedItems: [(supermarket: String, items: [CartItem])] {
        let grouped = Dictionary(grouping: appState.cartItems) { item in
            item.selectedPrice.supermarket.uppercased()
        }
        return grouped.map { (supermarket: $0.key, items: $0.value) }
            .sorted { $0.supermarket < $1.supermarket }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Fondo claro idéntico a la app
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                if appState.cartItems.isEmpty {
                    emptyCartView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Cabecera con resumen y acciones rápidas
                            headerActionRow

                            // Grupos por supermercado (VEA, CARREFOUR, etc.)
                            ForEach(groupedItems, id: \.supermarket) { group in
                                supermarketGroupSection(supermarket: group.supermarket, items: group.items)
                            }

                            // Botones de exportar lista / compartir
                            bottomActionsSection

                            Spacer().frame(height: 100)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Mi Lista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !appState.cartItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showClearConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.88, green: 0.22, blue: 0.22))
                        }
                    }
                }
            }
            .confirmationDialog(
                "¿Estás seguro de que quieres vaciar la lista?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Vaciar lista", role: .destructive) {
                    withAnimation {
                        appState.clearCart()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $showShareSheet) {
                ShareActivityView(text: shareText)
            }
        }
    }

    // MARK: - Header Action Row (Modo Changuito + Resumen)
    private var headerActionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.totalCartUnitsCount) ARTÍCULOS")
                    .font(.montserrat(.black, size: 10))
                    .tracking(1.0)
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))

                Text(formatPrice(appState.currentCartTotal))
                    .font(.montserrat(.black, size: 22))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
            }

            Spacer()

            // Botón Modo Changuito (para ir tachando mientras comprás)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isChanguitoMode.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isChanguitoMode ? "checkmark.circle.fill" : "cart")
                        .font(.system(size: 13, weight: .bold))
                    Text(isChanguitoMode ? "MODO COMPRA" : "CHANGUITO")
                        .font(.montserrat(.black, size: 11))
                        .tracking(0.5)
                }
                .foregroundColor(isChanguitoMode ? .white : Color(red: 0.13, green: 0.77, blue: 0.36))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    isChanguitoMode
                    ? Color(red: 0.13, green: 0.77, blue: 0.36)
                    : Color(red: 0.90, green: 0.98, blue: 0.93)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Supermarket Group Section (Referencia List 1.PNG)
    private func supermarketGroupSection(supermarket: String, items: [CartItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Título del Supermercado (ej. "VEA" en gris uppercase)
            HStack {
                Text(supermarket)
                    .font(.montserrat(.black, size: 15))
                    .tracking(1.0)
                    .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.62))

                Spacer()

                let subtotal = items.reduce(0.0) { $0 + $1.totalCost }
                Text("Subtotal: \(formatPrice(subtotal))")
                    .font(.montserrat(.bold, size: 12))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
            }
            .padding(.horizontal, 20)

            // Tarjetas de productos dentro de este supermercado
            VStack(spacing: 16) {
                ForEach(items) { item in
                    cartItemCard(item)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Tarjeta de Producto en Lista (Exacta a List 1.PNG)
    private func cartItemCard(_ item: CartItem) -> some View {
        // Buscar si existe un precio mejor o alternativa que rinda más en otro súper
        let betterAlternative = item.allPrices
            .filter { $0.inStock && $0.price > 0 && $0.supermarket != item.selectedPrice.supermarket }
            .sorted { a, b in
                let effA = a.pricePerUnit ?? a.price
                let effB = b.pricePerUnit ?? b.price
                return effA < effB
            }
            .first

        let isBetterPrice = betterAlternative != nil && (betterAlternative!.price < item.selectedPrice.price)

        return VStack(spacing: 0) {
            // Pill Flotante Superior (¡RINDE MÁS! o MÁS BARATO) si aplica
            if let better = betterAlternative, isBetterPrice {
                HStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation {
                            appState.replacePrice(for: item.id, with: better)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.system(size: 10, weight: .bold))

                            if let ppuBetter = better.pricePerUnit, let ppuCurrent = item.selectedPrice.pricePerUnit, ppuBetter < ppuCurrent {
                                Text("¡RINDE MÁS POR \(formatPrice(better.price))!")
                            } else {
                                Text("MÁS BARATO (\(formatPrice(better.price)))")
                            }
                        }
                        .font(.montserrat(.black, size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.05, green: 0.75, blue: 0.55)) // Teal/verde brillante
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .offset(y: 12)
                    .zIndex(10)
                }
                .padding(.trailing, 16)
            }

            // Barra Superior de Estado: [ 📌 PRINCIPAL / OPCIONAL ] + [ HACER OPCIONAL / PRINCIPAL ]
            HStack {
                // Indicador de tipo
                HStack(spacing: 5) {
                    Image(systemName: item.isOptional ? "arrow.triangle.swap" : "pin.fill")
                        .font(.system(size: 10))

                    Text(item.isOptional ? "OPCIONAL" : "PRINCIPAL")
                        .font(.montserrat(.black, size: 10))
                        .tracking(0.5)
                        .lineLimit(1)
                        .fixedSize()
                }
                .foregroundColor(.white)
                .padding(.leading, 12)

                Spacer()

                // Botón Magenta/Rosa "HACER OPCIONAL" / "HACER PRINCIPAL"
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation {
                        appState.toggleOptional(for: item)
                    }
                }) {
                    Text(item.isOptional ? "HACER PRINCIPAL" : "HACER OPCIONAL")
                        .font(.montserrat(.black, size: 9))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.93, green: 0.12, blue: 0.47)) // Magenta #E11D48
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
            .frame(height: 36)
            .background(Color(red: 0.40, green: 0.44, blue: 0.50)) // Slate-gray suave
            .clipShape(Capsule())
            .padding(.horizontal, 12)
            .padding(.top, 10)

            // Fila de Contenido: Imagen + Datos + Stepper Compacto
            HStack(alignment: .center, spacing: 12) {
                // Checkbox en modo changuito
                if isChanguitoMode {
                    Button(action: {
                        withAnimation {
                            appState.toggleItemCheck(withId: item.id)
                        }
                    }) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(item.isChecked ? Color(red: 0.13, green: 0.77, blue: 0.36) : Color(red: 0.78, green: 0.82, blue: 0.88))
                    }
                    .buttonStyle(.plain)
                }

                // Imagen en tarjeta redondeada
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.96, green: 0.97, blue: 0.98))
                        .frame(width: 58, height: 58)

                    if let img = item.imageUrl ?? item.selectedPrice.imageUrl, let url = URL(string: img) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                            } else {
                                Image(systemName: "basket.fill")
                                    .foregroundColor(Color(red: 0.75, green: 0.80, blue: 0.88))
                            }
                        }
                    } else {
                        Image(systemName: "basket.fill")
                            .foregroundColor(Color(red: 0.75, green: 0.80, blue: 0.88))
                    }
                }

                // Título + Precio Total + Tienda Link + Precio Unitario
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.productName)
                        .font(.montserrat(.bold, size: 13))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .lineLimit(2)
                        .strikethrough(item.isChecked)

                    HStack(alignment: .center, spacing: 6) {
                        Text(formatPrice(item.totalCost))
                            .font(.montserrat(.black, size: 15))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .layoutPriority(2)

                        if let urlStr = item.selectedPrice.url, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 10))
                                    Text("Tienda")
                                        .font(.montserrat(.bold, size: 9))
                                        .lineLimit(1)
                                }
                                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                                .clipShape(Capsule())
                            }
                            .fixedSize()
                            .layoutPriority(1)
                        }
                    }

                    // Precio de Referencia por Kilo / Litro
                    if let ppu = item.selectedPrice.pricePerUnit, let uLabel = item.selectedPrice.unitType {
                        HStack(spacing: 3) {
                            Text("⚖️")
                                .font(.system(size: 10))
                            Text("\(formatPrice(ppu)) / \(uLabel)")
                                .font(.montserrat(.bold, size: 10))
                                .foregroundColor(Color(red: 0.13, green: 0.65, blue: 0.35))
                                .lineLimit(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stepper Horizontal Compacto
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.updateQuantity(for: item, delta: -1)
                    }) {
                        Text("—")
                            .font(.montserrat(.bold, size: 14))
                            .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.62))
                            .frame(width: 20, height: 28)
                    }
                    .buttonStyle(.plain)

                    Text("\(item.quantity)")
                        .font(.montserrat(.black, size: 15))
                        .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))
                        .frame(minWidth: 16)

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        appState.updateQuantity(for: item, delta: 1)
                    }) {
                        Text("+")
                            .font(.montserrat(.bold, size: 16))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                            .frame(width: 20, height: 28)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.94, green: 0.96, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Botones de Exportar / Compartir
    private var bottomActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                generateShareText()
                showShareSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                    Text("COMPARTIR LISTA")
                        .font(.montserrat(.black, size: 13))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(red: 0.15, green: 0.83, blue: 0.40)) // Verde WhatsApp / ElMango
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.15, green: 0.83, blue: 0.40).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func generateShareText() {
        var text = "🛒 *Mi Lista de Compras en ElMango* 🥭\n\n"
        for group in groupedItems {
            text += "*\(group.supermarket)*\n"
            for item in group.items {
                let optTag = item.isOptional ? " [OPCIONAL]" : ""
                text += "• \(item.quantity)x \(item.productName)\(optTag) - \(formatPrice(item.totalCost))\n"
            }
            let sub = group.items.reduce(0.0) { $0 + $1.totalCost }
            text += "Subtotal: \(formatPrice(sub))\n\n"
        }
        text += "💰 *Total General: \(formatPrice(appState.currentCartTotal))*\n"
        text += "Comparado en Bahía Blanca con ElMango."
        shareText = text
    }

    // MARK: - Estado Vacío
    private var emptyCartView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.90, green: 0.98, blue: 0.93))
                    .frame(width: 110, height: 110)

                Image(systemName: "cart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
            }

            Text("Tu lista está vacía")
                .font(.montserrat(.black, size: 24))
                .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.18))

            Text("Buscá productos en el inicio y agregalos como principales u opcionales.")
                .font(.montserrat(.regular, size: 14))
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_AR")
        formatter.maximumFractionDigits = 0
        let str = formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
        return str.replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}

// Helper para compartir texto nativo
struct ShareActivityView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
