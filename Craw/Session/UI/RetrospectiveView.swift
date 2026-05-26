import SwiftUI

struct RetrospectiveView: View {
    let onSubmit: (_ focusDifficulty: Int) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            VStack(spacing: Theme.Spacing.sm) {
                Text("How hard was it to focus?")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                Text("Tap a number — 1 is easy, 5 is brutal.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        onSubmit(value)
                    } label: {
                        Text("\(value)")
                            .font(Theme.Typography.displaySm)
                            .foregroundStyle(Theme.Palette.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Theme.Palette.surfaceSoft)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.button)
                                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Focus difficulty \(value)")
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }
}
