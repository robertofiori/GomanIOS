//
//  MangoLogoView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct MangoLogoView: View {
    var size: CGFloat = 84

    public init(size: CGFloat = 84) {
        self.size = size
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Hoja superior
            MangoLeafShape()
                .fill(Color(red: 0.44, green: 0.53, blue: 0.28)) // Verde oliva
                .frame(width: size * 0.38, height: size * 0.22)
                .rotationEffect(.degrees(-15))
                .offset(x: -size * 0.12, y: -size * 0.04)

            // Cuerpo del Mango
            ZStack {
                MangoBodyShape()
                    .fill(Color(red: 0.77, green: 0.43, blue: 0.30)) // Terracota / Mango cálido
                    .frame(width: size * 0.85, height: size)
                    .rotationEffect(.degrees(6))

                // Carrito de compras blanco dentro del mango
                ShoppingCartIcon()
                    .fill(Color.white)
                    .frame(width: size * 0.46, height: size * 0.44)
                    .offset(x: size * 0.04, y: size * 0.02)
            }
        }
        .frame(width: size, height: size * 1.05)
    }
}

// MARK: - Forma orgánica del Mango
struct MangoBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.52, y: h * 0.05))
        
        // Curva superior derecha hacia el lomo del mango
        path.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.40),
            control1: CGPoint(x: w * 0.78, y: h * 0.05),
            control2: CGPoint(x: w * 0.98, y: h * 0.22)
        )
        
        // Lomo hacia la base redondeada
        path.addCurve(
            to: CGPoint(x: w * 0.70, y: h * 0.96),
            control1: CGPoint(x: w * 0.92, y: h * 0.65),
            control2: CGPoint(x: w * 0.88, y: h * 0.90)
        )
        
        // Base inferior
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.88),
            control1: CGPoint(x: w * 0.52, y: h * 1.02),
            control2: CGPoint(x: w * 0.32, y: h * 0.98)
        )
        
        // Panza izquierda hacia la hendidura
        path.addCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.45),
            control1: CGPoint(x: w * 0.10, y: h * 0.75),
            control2: CGPoint(x: w * 0.05, y: h * 0.58)
        )
        
        // De la hendidura al tallo superior
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.05),
            control1: CGPoint(x: w * 0.20, y: h * 0.25),
            control2: CGPoint(x: w * 0.35, y: h * 0.06)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Forma de la Hoja
struct MangoLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: h))
        path.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w * 0.15, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: h), control: CGPoint(x: w * 0.85, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Icono vectorial de Carrito de Compras recortado
struct ShoppingCartIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Canasta exterior
        let basketPath = Path { p in
            // Manillar
            p.move(to: CGPoint(x: 0, y: h * 0.10))
            p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.10))
            p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.65))
            p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.65))
            p.addLine(to: CGPoint(x: w * 1.00, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.24, y: h * 0.20))
        }
        
        // Trazado de líneas de la canasta
        let strokedBasket = basketPath.strokedPath(StrokeStyle(lineWidth: w * 0.09, lineCap: .round, lineJoin: .round))
        path.addPath(strokedBasket)

        // Rueda delantera
        let wheelRadius = w * 0.08
        path.addEllipse(in: CGRect(x: w * 0.36 - wheelRadius, y: h * 0.85 - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2))

        // Rueda trasera
        path.addEllipse(in: CGRect(x: w * 0.80 - wheelRadius, y: h * 0.85 - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2))

        // Rejilla interior de la canasta
        // Línea horizontal intermedia
        let hLine = Path { p in
            p.move(to: CGPoint(x: w * 0.28, y: h * 0.42))
            p.addLine(to: CGPoint(x: w * 0.94, y: h * 0.42))
        }.strokedPath(StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
        path.addPath(hLine)

        // Líneas verticales
        let v1 = Path { p in
            p.move(to: CGPoint(x: w * 0.46, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.48, y: h * 0.65))
        }.strokedPath(StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
        path.addPath(v1)

        let v2 = Path { p in
            p.move(to: CGPoint(x: w * 0.68, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.65))
        }.strokedPath(StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
        path.addPath(v2)

        return path
    }
}
