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
    @State private var showOptimizationDetails = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if appState.cartItems.isEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("Mi Lista")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !appState.cartItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Vaciar", role: .destructive) {
                            showClearConfirmation = true
                        }
                        .foregroundColor(.red)
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
            .sheet(isPresented: $showOptimizationDetails) {
                optimizationDetailsSheet
            }
        }
    }

    // MARK: - Cart Content View
    private var cartContentView: some View {
        List {
            // Sección de Optimización y Recomendación
            Section {
                optimizationCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Sección de Productos
            Section {
                ForEach(appState.cartItems) { item in
                    cartItemRow(item)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = appState.cartItems[index]
                        appState.removeItem(withId: item.id)
                    }
                }
            } header: {
                HStack {
                    Text("\(appState.totalCartUnitsCount) artículos en tu lista")
                    Spacer()
                    Text("Total: \(formatPrice(appState.currentCartTotal))")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            } footer: {
                Text("Deslizá hacia la izquierda para eliminar un producto.")
                    .font(.caption2)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Optimization Banner Card
    private var optimizationCard: some View {
        let opt = appState.optimizationResults
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                        Text("Canasta Optimizada")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    if let best = opt.bestSupermarket {
                        Text("El más conveniente es \(best.supermarket)")
                            .font(.headline)
                            .fontWeight(.bold)

                        if best.savingsVsCurrent > 0 {
                            Text("Ahorrás \(formatPrice(best.savingsVsCurrent)) frente al promedio.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Comparando precios de tu canasta...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Ver detalle") {
                    showOptimizationDetails = true
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .clipShape(Capsule())
            }

            // Barra rápida de comparación entre supermercados
            if !opt.totalsPerSupermarket.isEmpty {
                Divider()
                HStack(spacing: 8) {
                    ForEach(opt.totalsPerSupermarket.prefix(3)) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            SupermarketBadge(item.supermarket, style: .compact)
                            Text(formatPrice(item.effectiveTotal))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Cart Item Row
    private func cartItemRow(_ item: CartItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Checkbox para marcar cuando compras en el local
            Button(action: {
                withAnimation {
                    appState.toggleItemCheck(withId: item.id)
                }
            }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Datos del producto
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    SupermarketBadge(item.selectedPrice.supermarket, style: .compact)

                    Text(formatPrice(item.selectedPrice.price) + " c/u")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 4)

            // Selector de cantidad (+ / -)
            HStack(spacing: 8) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        appState.updateQuantity(for: item, delta: -1)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(item.quantity)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(minWidth: 20)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        appState.updateQuantity(for: item, delta: 1)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 2)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 46))
                    .foregroundColor(.green)
            }

            Text("Tu lista está vacía")
                .font(.title2)
                .fontWeight(.bold)

            Text("Buscá productos en el catálogo o escaneá códigos de barra para empezar a comparar precios y ahorrar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
        }
    }

    // MARK: - Optimization Details Sheet
    private var optimizationDetailsSheet: some View {
        NavigationStack {
            let opt = appState.optimizationResults
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comparativa General")
                            .font(.headline)
                        Text("Calculamos el total que pagarías si compraras toda tu lista en un solo supermercado, sumando promociones bancarias aplicables hoy.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Totales por Comercio") {
                    ForEach(opt.totalsPerSupermarket) { total in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    SupermarketBadge(total.supermarket)
                                    if let disc = total.appliedDiscount {
                                        Text(disc)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text("\(total.itemCount) de \(appState.cartItems.count) productos encontrados (\(total.matchPercentage)%)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatPrice(total.effectiveTotal))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(total.supermarket == opt.bestSupermarket?.supermarket ? .green : .primary)

                                if total.savingsVsCurrent > 0 {
                                    Text("Ahorrás \(formatPrice(total.savingsVsCurrent))")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Mínimo Teórico Dividido") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Comprando cada producto en su súper más barato:")
                                .font(.subheadline)
                            Spacer()
                            Text(formatPrice(opt.theoreticalMin))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }

                        if appState.currentCartTotal > opt.theoreticalMin {
                            Text("Podrías ahorrar hasta \(formatPrice(appState.currentCartTotal - opt.theoreticalMin)) repartiendo la compra.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Optimizador de Canasta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { showOptimizationDetails = false }
                }
            }
        }
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
