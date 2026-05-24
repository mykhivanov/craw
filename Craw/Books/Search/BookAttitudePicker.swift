import SwiftUI

struct BookAttitudePicker: View {
    let result: BookSearchResult
    let onConfirm: (BookAttitude) -> Void
    let onCancel: () -> Void

    @State private var selection: BookAttitude?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header

                VStack(spacing: Theme.Spacing.md) {
                    OnboardingSelectableCard(
                        icon: "sparkles",
                        title: "For fun",
                        subtitle: "Just to enjoy reading.",
                        isSelected: selection == .entertainment,
                        action: { selection = .entertainment }
                    )
                    OnboardingSelectableCard(
                        icon: "graduationcap.fill",
                        title: "To study",
                        subtitle: "Learning or growth.",
                        isSelected: selection == .study,
                        action: { selection = .study }
                    )
                }

                Spacer(minLength: 0)

                addButton
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.base)
            .background(Theme.Palette.canvas)
            .navigationTitle("Add to library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .tint(Theme.Palette.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Why are you adding")
                .font(Theme.Typography.titleSm)
                .foregroundStyle(Theme.Palette.muted)
            Text("“\(result.title)”?")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
        }
    }

    private var addButton: some View {
        Button {
            if let selection {
                onConfirm(selection)
            }
        } label: {
            Text("Add to library")
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.canvas)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(selection == nil ? Theme.Palette.rauschDisabled : Theme.Palette.rausch)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(selection == nil)
        .accessibilityLabel("Add to library")
    }
}

#Preview("No selection") {
    BookAttitudePicker(
        result: BookSearchResult(
            id: "1",
            title: "Project Hail Mary",
            author: "Andy Weir",
            totalPages: 480
        ),
        onConfirm: { _ in },
        onCancel: {}
    )
}

#Preview("Entertainment selected") {
    StatefulPreviewWrapper(BookAttitude.entertainment) { binding in
        BookAttitudePicker(
            result: BookSearchResult(
                id: "1",
                title: "Project Hail Mary",
                author: "Andy Weir",
                totalPages: 480
            ),
            onConfirm: { _ in },
            onCancel: {}
        )
        .onAppear {
            binding.wrappedValue = .entertainment
        }
    }
}

private struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
