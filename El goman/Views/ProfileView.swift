//
//  ProfileView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLocationPicker = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Sección de Ubicación
                Section("Ubicación y Sucursales") {
                    Button(action: { showLocationPicker = true }) {
                        HStack {
                            Label("Ciudad actual", systemImage: "mappin.and.ellipse")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(appState.selectedLocation.city)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Sección de Billeteras y Promociones Bancarias
                Section {
                    ForEach(BankDiscount.availableDiscounts) { bank in
                        Toggle(isOn: Binding(
                            get: { appState.selectedBanks.contains(bank.id) },
                            set: { _ in appState.toggleBank(bank.id) }
                        )) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(bank.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bank.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text("\(Int(bank.discount * 100))% de reintegro en comercios adheridos")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Mis Medios de Pago y Descuentos")
                } footer: {
                    Text("Los descuentos se aplican automáticamente en 'Mi Lista' según el día de la semana vigente.")
                }

                // Supermercados relevados
                Section("Supermercados Relevados") {
                    Label("Vea Supermercados", systemImage: "cart.fill")
                    Label("Carrefour Argentina", systemImage: "cart.fill")
                    Label("ChangoMás", systemImage: "cart.fill")
                    Label("La Cooperativa Obrera", systemImage: "cart.fill")
                }

                // Información
                Section("Acerca de") {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0 (ElMango)")
                            .foregroundColor(.secondary)
                    }

                    if let url = URL(string: "https://robertofiori.github.io/superscan/") {
                        Link(destination: url) {
                            HStack {
                                Label("Versión Web (Superscan)", systemImage: "globe")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 85)
            }
            .sheet(isPresented: $showLocationPicker) {
                NavigationStack {
                    List(LocationData.availableLocations) { loc in
                        Button(action: {
                            appState.selectedLocation = loc
                            showLocationPicker = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.city)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("\(loc.province) • CP \(loc.zipCode)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if appState.selectedLocation.id == loc.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                    .navigationTitle("Seleccionar Ciudad")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cerrar") { showLocationPicker = false }
                        }
                    }
                }
            }
        }
    }
}
