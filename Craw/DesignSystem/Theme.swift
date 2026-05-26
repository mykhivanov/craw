import SwiftUI

enum Theme {
    enum Palette {
        static let rausch = Color(hex: 0xFF385C)
        static let rauschActive = Color(hex: 0xE00B41)
        static let rauschDisabled = Color(hex: 0xFFD1DA)
        static let rauschTint = Color(hex: 0xFFF1F4)
        static let ink = Color(hex: 0x222222)
        static let body = Color(hex: 0x3F3F3F)
        static let muted = Color(hex: 0x6A6A6A)
        static let mutedSoft = Color(hex: 0x929292)
        static let hairline = Color(hex: 0xDDDDDD)
        static let hairlineSoft = Color(hex: 0xEBEBEB)
        static let surfaceSoft = Color(hex: 0xF7F7F7)
        static let surfaceStrong = Color(hex: 0xF2F2F2)
        static let surfaceCard = Color(hex: 0xFFFFFF)
        static let canvas = Color(hex: 0xFFFFFF)
        static let trendUp = Color(hex: 0x2D8A47)
        static let trendDown = Color(hex: 0xC13515)
    }

    enum Radius {
        static let button: CGFloat = 8
        static let card: CGFloat = 14
        static let pill: CGFloat = 9999
    }

    enum Spacing {
        static let unit: CGFloat = 8
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let base: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let section: CGFloat = 64
    }

    enum Elevation {
        static let cardColor = Color.black.opacity(0.10)
        static let cardRadius: CGFloat = 8
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 4
    }

    enum Typography {
        private static let family = "Airbnb Cereal VF"

        static let displayHuge = Font.custom(family, size: 56).weight(.bold)
        static let displayNumeric = Font.custom(family, size: 44).weight(.semibold)
        static let onboardingHero = Font.custom(family, size: 32).weight(.semibold)
        static let displayLg = Font.custom(family, size: 22).weight(.medium)
        static let displaySm = Font.custom(family, size: 20).weight(.semibold)
        static let titleMd = Font.custom(family, size: 16).weight(.semibold)
        static let titleSm = Font.custom(family, size: 16).weight(.medium)
        static let bodyLg = Font.custom(family, size: 18).weight(.regular)
        static let bodyMd = Font.custom(family, size: 16).weight(.regular)
        static let bodySm = Font.custom(family, size: 14).weight(.regular)
        static let caption = Font.custom(family, size: 14).weight(.medium)
        static let captionSm = Font.custom(family, size: 13).weight(.regular)
        static let badge = Font.custom(family, size: 11).weight(.semibold)
        static let microLabel = Font.custom(family, size: 12).weight(.bold)
        static let buttonMd = Font.custom(family, size: 16).weight(.medium)
        static let buttonSm = Font.custom(family, size: 14).weight(.medium)
    }
}

extension View {
    func crawCardShadow() -> some View {
        shadow(
            color: Theme.Elevation.cardColor,
            radius: Theme.Elevation.cardRadius,
            x: Theme.Elevation.cardX,
            y: Theme.Elevation.cardY
        )
    }
}
