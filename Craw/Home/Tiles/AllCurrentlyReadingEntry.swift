import SwiftUI

struct AllCurrentlyReadingEntry: View {
    let inProgressCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.base) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 40, height: 40)
                    .background(Theme.Palette.surfaceStrong, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("All currently reading")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(subtitle)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .tileCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("All currently reading — \(subtitle)")
    }

    private var subtitle: String {
        switch inProgressCount {
        case 0: "Add your first book"
        case 1: "1 book in progress"
        default: "\(inProgressCount) books in progress"
        }
    }
}
