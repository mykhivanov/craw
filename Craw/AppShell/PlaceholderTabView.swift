import SwiftUI

struct PlaceholderTabView: View {
    let title: String
    let message: String

    init(title: String, message: String = "Coming soon") {
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            Image(systemName: "hourglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.Palette.mutedSoft)
            Text(title)
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
            Text(message)
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }
}

#Preview {
    PlaceholderTabView(title: "Quotes")
}
