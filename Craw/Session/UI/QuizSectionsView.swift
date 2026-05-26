import SwiftUI

struct QuizSectionsView: View {
    let bookName: String
    let onPick: (String) -> Void
    let onSkip: () -> Void
    let onError: () -> Void

    @State private var sections: [String] = []
    @State private var loadState: LoadState = .loading
    @State private var pageEntry: String = ""

    private enum LoadState: Equatable {
        case loading
        case loaded
        case failed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    sectionsList
                    pageInput
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .background(Theme.Palette.canvas)
        .task {
            await loadSections()
        }
    }

    private var topBar: some View {
        HStack {
            Text("Quiz")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            Spacer()
            Button("Skip", action: onSkip)
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(Theme.Palette.muted)
        }
        .padding(Theme.Spacing.base)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Which part did you finish?")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
            Text("Pick a section or enter the page you're on.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    @ViewBuilder
    private var sectionsList: some View {
        switch loadState {
        case .loading:
            ProgressView()
                .tint(Theme.Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
        case .loaded:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    Button {
                        onPick(section)
                    } label: {
                        HStack {
                            Text(section)
                                .font(Theme.Typography.bodyMd)
                                .foregroundStyle(Theme.Palette.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.Palette.muted)
                        }
                        .padding(Theme.Spacing.base)
                        .background(Theme.Palette.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .failed:
            EmptyView()
        }
    }

    private var pageInput: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Or enter the page you're on")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(spacing: Theme.Spacing.sm) {
                TextField("Page number", text: $pageEntry)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = pageEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onPick(trimmed)
                } label: {
                    Text("Confirm")
                        .font(Theme.Typography.buttonSm)
                        .foregroundStyle(Theme.Palette.canvas)
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(height: 40)
                        .background(pageEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Theme.Palette.rauschDisabled
                            : Theme.Palette.rausch)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .disabled(pageEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func loadSections() async {
        do {
            let result = try await AppEnvironment.liveAPIClient.quizSections(bookName: bookName)
            sections = result
            loadState = .loaded
        } catch {
            loadState = .failed
            onError()
        }
    }
}
