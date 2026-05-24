import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.Palette.canvas.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.Palette.rausch)
                ProgressView()
                    .tint(Theme.Palette.muted)
            }
        }
    }
}

#Preview {
    SplashView()
}
