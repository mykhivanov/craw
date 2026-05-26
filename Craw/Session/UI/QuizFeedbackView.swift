import SwiftUI

struct QuizFeedbackView: View {
    let mark: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: glyph)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(accent)
                Text(title)
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }

    private var title: String {
        switch mark {
        case 1: "Consider rereading"
        case 2: "Good"
        default: "Great session"
        }
    }

    private var subtitle: String? {
        switch mark {
        case 1: "The details slipped past. A second pass usually sticks."
        case 2: "Solid — most of it stuck."
        default: "You nailed it."
        }
    }

    private var glyph: String {
        switch mark {
        case 1: "arrow.uturn.left.circle"
        case 2: "checkmark.circle"
        default: "sparkles"
        }
    }

    private var accent: Color {
        switch mark {
        case 1: Theme.Palette.muted
        case 2: Theme.Palette.ink
        default: Theme.Palette.rausch
        }
    }
}
