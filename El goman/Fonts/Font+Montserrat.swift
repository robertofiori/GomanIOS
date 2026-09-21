//
//  Font+Montserrat.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI
import CoreText

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
        FontRegistrar.registerFontsIfNeeded()
        return Font.custom(weight.fontName, size: size)
    }
}

public enum FontRegistrar {
    private static var hasRegistered = false

    public static func registerFontsIfNeeded() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let fontNames = [
            "Montserrat-Regular",
            "Montserrat-SemiBold",
            "Montserrat-Bold",
            "Montserrat-BoldItalic",
            "Montserrat-ExtraBold",
            "Montserrat-ExtraBoldItalic",
            "Montserrat-Black",
            "Montserrat-BlackItalic"
        ]

        for fontName in fontNames {
            if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            } else if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf", subdirectory: "Fonts") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
