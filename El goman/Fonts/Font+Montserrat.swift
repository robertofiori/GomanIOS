//
//  Font+Montserrat.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public extension Font {
    enum MontserratWeight {
        case regular
        case semiBold
        case bold
        case extraBold
        case black
        case boldItalic
        case extraBoldItalic
        case blackItalic

        var fontName: String {
            switch self {
            case .regular: return "Montserrat-Regular"
            case .semiBold: return "Montserrat-SemiBold"
            case .bold: return "Montserrat-Bold"
            case .extraBold: return "Montserrat-ExtraBold"
            case .black: return "Montserrat-Black"
            case .boldItalic: return "Montserrat-BoldItalic"
            case .extraBoldItalic: return "Montserrat-ExtraBoldItalic"
            case .blackItalic: return "Montserrat-BlackItalic"
            }
        }
    }

    static func montserrat(_ weight: MontserratWeight = .regular, size: CGFloat) -> Font {
        Font.custom(weight.fontName, size: size)
    }
}
