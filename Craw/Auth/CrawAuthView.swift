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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.base) {
            Text("ALMOST THERE")
                .font(Theme.Typography.microLabel)
                .foregroundStyle(Theme.Palette.rausch)
                .tracking(0.6)

            Text("Required to save your progress")
                .font(Theme.Typography.onboardingHero)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

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
                .frame(height: 140)

            MascotSpeechBubble(text: "Required to save your progress")
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CrawAuthView()
}
