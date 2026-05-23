import SwiftUI

struct LibraryEmptyState: View {
    let onAddTapped: (() -> Void)?

    init(onAddTapped: (() -> Void)? = nil) {
        self.onAddTapped = onAddTapped
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            Image(systemName: "books.vertical")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.Palette.mutedSoft)
            VStack(spacing: Theme.Spacing.xs) {
                Text("Your library is empty")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Add the first book to start a reading streak.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
            }
            AddBookButton(onTapped: onAddTapped)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

struct ReadingNowEmptyState: View {
    let onAddTapped: (() -> Void)?

    init(onAddTapped: (() -> Void)? = nil) {
        self.onAddTapped = onAddTapped
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Nothing on your nightstand")
                .font(Theme.Typography.titleSm)
                .foregroundStyle(Theme.Palette.ink)
            Text("Pick a new book to start a fresh session.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .multilineTextAlignment(.center)
            AddBookButton(onTapped: onAddTapped)
                .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

private struct AddBookButton: View {
    let onTapped: (() -> Void)?

    var body: some View {
        Button {
            onTapped?()
        } label: {
            Text("Add a book")
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(Theme.Palette.canvas)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Palette.rausch)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}
