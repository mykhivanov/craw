import SwiftUI

struct BookDetailPlaceholder: View {
    let book: Book

    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            Text(book.title)
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
            Text("Detail view coming soon")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Theme.Palette.canvas)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
