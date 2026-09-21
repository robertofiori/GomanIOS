//
//  LoginView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct LoginView: View {
    @State private var authService = AuthService.shared
    @State private var isSigningIn = false
    @State private var errorMessage: String? = nil

    let onLoginSuccess: () -> Void

    public init(onLoginSuccess: @escaping () -> Void = {}) {
        self.onLoginSuccess = onLoginSuccess
    }

    public var body: some View {
        ZStack {
            // Fondo gris suave de la app web (#f7f8fa)
            Color(red: 0.97, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // 1. Header con Logo ElMango y Lema
                    VStack(alignment: .center, spacing: 2) {
                        MangoLogoView(width: 140)
                            .scaleEffect(1.05)
                            .padding(.top, 24)

                        HStack(spacing: 0) {
                            Text("¡Ahorra en tu compra ")
                                .font(.montserrat(.black, size: 20))
                                .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))

                            Text("realmente")
                                .font(.montserrat(.blackItalic, size: 22))
                                .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))

                            Text("!")
                                .font(.montserrat(.black, size: 22))
                                .foregroundColor(Color(red: 0.06, green: 0.09, blue: 0.16))
                        }
                    }

                    // 2. Ticket Mock con Efecto Recibo de Supermercado
                    receiptTicketCard

                    // 3. Texto descriptivo
                    Text("Inicia sesión con tu cuenta de Google para guardar tus listas, métodos de pago y recibir alertas.")
                        .font(.montserrat(.semiBold, size: 14))
                        .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55)) // slate-500
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .lineSpacing(3)

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.montserrat(.semiBold, size: 12))
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }

                    // 4. Botón "Continuar con Google"
                    Button(action: {
                        handleGoogleLogin()
                    }) {
                        HStack(spacing: 14) {
                            if isSigningIn {
                                ProgressView()
                                    .tint(Color(red: 0.13, green: 0.77, blue: 0.36))
                            } else {
                                // Icono Google / Login
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.90, green: 0.98, blue: 0.93))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))
                                }

                                Text("Continuar con Google")
                                    .font(.montserrat(.black, size: 16))
                                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.24))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(red: 0.92, green: 0.94, blue: 0.96), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .disabled(isSigningIn)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }

    // MARK: - Ticket Mock de Supermercado
    private var receiptTicketCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Píldora superior tenue
                Capsule()
                    .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                    .frame(width: 44, height: 4)
                    .padding(.top, 4)

                // Lista de productos con descuento
                VStack(spacing: 9) {
                    ticketItemRow(name: "LECHE ENTERA", originalPrice: "$1.200", offerPrice: "$850")
                    ticketItemRow(name: "CAFÉ MOLIDO", originalPrice: "$4.500", offerPrice: "$3.200")
                    ticketItemRow(name: "PAN ARTESANO", originalPrice: "$2.100", offerPrice: "$1.500")
                    ticketItemRow(name: "PACK YOGUR", originalPrice: "$1.800", offerPrice: "$1.200")
                }
                .padding(.top, 6)

                // Badges de Ubicación y Tarjeta
                HStack(spacing: 8) {
                    Spacer()
                    Circle()
                        .fill(Color(red: 0.93, green: 0.96, blue: 1.0))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "mappin")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                        )

                    Circle()
                        .fill(Color(red: 0.98, green: 0.92, blue: 0.99))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.75, green: 0.18, blue: 0.85))
                        )
                }
                .padding(.top, 4)

                // Línea punteada de corte
                DashedLine()
                    .stroke(Color(red: 0.88, green: 0.90, blue: 0.94), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(height: 1)
                    .padding(.vertical, 6)

                // Total a Pagar
                HStack(alignment: .center) {
                    Text("A PAGAR")
                        .font(.montserrat(.black, size: 12))
                        .tracking(1.5)
                        .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))

                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.36))

                        Text("$ 6.750")
                            .font(.montserrat(.black, size: 24))
                            .foregroundColor(Color(red: 0.42, green: 0.13, blue: 0.65)) // Morado oscuro
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 10,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: 28
                )
            )

            // Borde inferior dentado tipo ticket
            TicketScallopEdge()
                .fill(Color.white)
                .frame(height: 10)
        }
        .frame(maxWidth: 320)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func ticketItemRow(name: String, originalPrice: String, offerPrice: String) -> some View {
        HStack {
            Text(name)
                .font(.montserrat(.bold, size: 11))
                .tracking(1.0)
                .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))

            Spacer()

            HStack(spacing: 6) {
                Text(originalPrice)
                    .font(.montserrat(.bold, size: 12))
                    .strikethrough(true, color: Color(red: 0.58, green: 0.64, blue: 0.72))
                    .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.82))

                Text(offerPrice)
                    .font(.montserrat(.black, size: 14))
                    .foregroundColor(Color(red: 0.49, green: 0.23, blue: 0.73))
            }
        }
    }

    // MARK: - Login Action
    private func handleGoogleLogin() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSigningIn = true
        errorMessage = nil

        Task {
            await authService.signInWithGoogle()
            await MainActor.run {
                self.isSigningIn = false
                self.onLoginSuccess()
            }
        }
    }
}

// MARK: - Línea punteada
private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Borde de Ticket tipo Scalloped
private struct TicketScallopEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let toothWidth: CGFloat = 16
        let toothHeight: CGFloat = rect.height
        let count = Int(rect.width / toothWidth) + 1

        path.move(to: CGPoint(x: 0, y: 0))
        for i in 0..<count {
            let startX = CGFloat(i) * toothWidth
            let midX = startX + toothWidth / 2
            let endX = startX + toothWidth

            path.addLine(to: CGPoint(x: startX, y: 0))
            path.addLine(to: CGPoint(x: midX, y: toothHeight))
            path.addLine(to: CGPoint(x: endX, y: 0))
        }
        path.closeSubpath()
        return path
    }
}
