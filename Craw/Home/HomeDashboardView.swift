import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @Query(filter: BookLibraryReader.inProgressPredicate, sort: BookLibraryReader.defaultSort)
    private var inProgressBooks: [Book]

    @Query(filter: BookLibraryReader.finishedPredicate, sort: BookLibraryReader.defaultSort)
    private var finishedBooks: [Book]

    @Query(sort: [SortDescriptor(\ReadingDay.date, order: .reverse)])
    private var readingDays: [ReadingDay]

    @State private var isSearchPresented = false

    private var isLibraryEmpty: Bool {
        inProgressBooks.isEmpty && finishedBooks.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                GreetingSection()
                WeekStripSection(days: readingDays)
                StatCardsSection(days: readingDays)
                tileColumn
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.top, Theme.Spacing.base)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Palette.canvas)
        .navigationDestination(for: Book.self) { book in
            BookDetailView(book: book)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isSearchPresented) {
            BookSearchView()
        }
    }

    private var tileColumn: some View {
        VStack(spacing: Theme.Spacing.md) {
            if isLibraryEmpty {
                MascotEmptyTile(onAddTapped: presentSearch)
            }
            EntertainmentBookTile(onAddTapped: presentSearch)
            StudyBookTile(onAddTapped: presentSearch)
            LiveCounterTile()
            QuoteOfTheDayTile()
        }
    }

    private func presentSearch() {
        isSearchPresented = true
    }
}

#Preview("Full dashboard — seeded") {
    let container = CrawModelContainer.previewInMemory()
    SampleData.seed(into: ModelContext(container))
    return NavigationStack { HomeDashboardView() }
        .modelContainer(container)
}

#Preview("Empty library") {
    NavigationStack { HomeDashboardView() }
        .modelContainer(CrawModelContainer.previewInMemory())
}

#Preview("Only-finished library") {
    let container = CrawModelContainer.previewInMemory()
    let ctx = ModelContext(container)
    ctx.insert(Book(
        title: "Done & Dusted",
        author: "An Author",
        totalPages: 200,
        currentPage: 200,
        attitude: .entertainment
    ))
    try? ctx.save()
    return NavigationStack { HomeDashboardView() }
        .modelContainer(container)
}
