import SwiftData
import SwiftUI

struct BookSearchView: View {
    /// When non-nil, search-result taps insert directly with this attitude and skip the picker.
    let presetAttitude: BookAttitude?

    init(presetAttitude: BookAttitude? = nil) {
        self.presetAttitude = presetAttitude
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var store: BookSearchStore = AppEnvironment.makeBookSearchStore()
    @State private var queryText: String = ""
    @State private var pendingAttitudeChoice: BookSearchResult?

    var body: some View {
        NavigationStack {
            content
                .background(Theme.Palette.canvas)
                .navigationTitle("Add a book")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { dismiss() }
                            .tint(Theme.Palette.ink)
                    }
                }
        }
        .searchable(
            text: $queryText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by title or author"
        )
        .onChange(of: queryText) { _, newValue in
            store.updateQuery(newValue)
        }
        .sheet(item: $pendingAttitudeChoice) { result in
            BookAttitudePicker(
                result: result,
                onConfirm: { attitude in
                    insert(result, attitude: attitude)
                    pendingAttitudeChoice = nil
                },
                onCancel: { pendingAttitudeChoice = nil }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle:
            VStack(spacing: Theme.Spacing.sm) {
                Text("Search by title or author")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading:
            VStack(spacing: Theme.Spacing.md) {
                ProgressView().tint(Theme.Palette.muted)
                Text("Searching…")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .results(results):
            resultsList(results)
        case let .empty(query):
            VStack(spacing: Theme.Spacing.sm) {
                Text("No matches for “\(query)”")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Try a different title or author.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .error(message):
            VStack(spacing: Theme.Spacing.md) {
                Text(message)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                Button {
                    store.retry()
                } label: {
                    Text("Try again")
                        .font(Theme.Typography.buttonSm)
                        .foregroundStyle(Theme.Palette.canvas)
                        .padding(.horizontal, Theme.Spacing.base)
                        .frame(height: 40)
                        .background(Theme.Palette.rausch)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func resultsList(_ results: [BookSearchResult]) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    Button {
                        if let presetAttitude {
                            insert(result, attitude: presetAttitude)
                        } else {
                            pendingAttitudeChoice = result
                        }
                    } label: {
                        BookSearchResultRow(result: result)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if index >= results.count - 5 {
                            store.loadMore()
                        }
                    }
                }
                if store.hasMore {
                    ProgressView()
                        .tint(Theme.Palette.muted)
                        .padding(.vertical, Theme.Spacing.base)
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private func insert(_ result: BookSearchResult, attitude: BookAttitude) {
        let book = Book(
            remoteID: result.id,
            title: result.title,
            author: result.author,
            coverImageURL: result.coverImageURL,
            isbn: result.isbn,
            totalPages: result.totalPages,
            attitude: attitude
        )
        modelContext.insert(book)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    BookSearchView()
        .modelContainer(CrawModelContainer.previewInMemory())
}
