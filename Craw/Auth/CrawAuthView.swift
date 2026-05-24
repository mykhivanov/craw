import ClerkKit
import ClerkKitUI
import SwiftUI

struct CrawAuthView: View {
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.base)

            AuthView(mode: .signInOrUp, isDismissable: false)
                .environment(\.clerkTheme, clerkTheme)
                .environment(\.colorScheme, .light)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas.ignoresSafeArea())
    }

    private var clerkTheme: ClerkTheme {
        ClerkTheme(
            colors: clerkColors,
            design: .init(borderRadius: Theme.Radius.button)
        )
    }

    private var clerkColors: ClerkTheme.Colors {
        var colors = ClerkTheme.Colors(
            primary: Theme.Palette.rausch,
            background: Theme.Palette.canvas,
            input: Theme.Palette.surfaceSoft,
            danger: Theme.Palette.trendDown,
            foreground: Theme.Palette.ink,
            mutedForeground: Theme.Palette.muted,
            primaryForeground: .white,
            inputForeground: Theme.Palette.ink,
            neutral: Theme.Palette.ink,
            ring: Theme.Palette.rausch,
            muted: Theme.Palette.surfaceSoft,
            shadow: .black,
            border: Theme.Palette.ink
        )
        colors.buttonBorder = Theme.Palette.ink
        return colors
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.base) {
            Text("ALMOST THERE")
                .font(Theme.Typography.microLabel)
                .foregroundStyle(Theme.Palette.rausch)
                .tracking(0.6)
            mascotIntro
                .padding(.top, Theme.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
    }

    private var mascotIntro: some View {
        VStack(spacing: Theme.Spacing.base) {
            Image("mascotCraw")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CrawAuthView()
}
