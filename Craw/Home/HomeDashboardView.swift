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

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                GreetingSection()
                WeekStripSection(days: readingDays)
                StatCardsSection(days: readingDays)
                bookSections
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

    @ViewBuilder
    private var bookSections: some View {
        if inProgressBooks.isEmpty, finishedBooks.isEmpty {
            LibraryEmptyState(onAddTapped: presentSearch)
        } else {
            BookListSection(
                title: "Reading Now",
                books: inProgressBooks,
                showsAddButton: true,
                onAddTapped: presentSearch,
                emptyContent: { AnyView(ReadingNowEmptyState(onAddTapped: presentSearch)) }
            )
            if !finishedBooks.isEmpty {
                BookListSection(
                    title: "Finished",
                    books: finishedBooks,
                    showsAddButton: false
                )
            }
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
        currentPage: 200
    ))
    try? ctx.save()
    return NavigationStack { HomeDashboardView() }
        .modelContainer(container)
}

#Preview("In-progress only") {
    let container = CrawModelContainer.previewInMemory()
    let ctx = ModelContext(container)
    ctx.insert(Book(
        title: "Currently Reading",
        author: "An Author",
        totalPages: 400,
        currentPage: 120
    ))
    try? ctx.save()
    return NavigationStack { HomeDashboardView() }
        .modelContainer(container)
}
