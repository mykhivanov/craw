import SwiftUI

struct RestorationPromptView: View {
    let book: Book
    let snapshot: ActiveSessionSnapshot
    let onResume: () -> Void
    let onStopAndSave: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.Palette.rausch)
            VStack(spacing: Theme.Spacing.xs) {
                Text("Session in progress")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("You were reading \"\(book.title)\". Resume or stop and save what you've got?")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: Theme.Spacing.sm) {
                Button(action: onResume) {
                    Text("Resume")
                        .font(Theme.Typography.buttonMd)
                        .foregroundStyle(Theme.Palette.canvas)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.Palette.rausch)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                Button(action: onStopAndSave) {
                    Text("Stop and save")
                        .font(Theme.Typography.buttonMd)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.Palette.surfaceStrong)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
    }
}
