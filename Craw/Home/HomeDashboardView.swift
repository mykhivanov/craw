import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @Environment(SessionEngine.self) private var engine

    let onStartSession: ((Book) -> Void)?
    let onShowAllCurrentlyReading: () -> Void

    @Query(filter: BookLibraryReader.inProgressPredicate, sort: BookLibraryReader.defaultSort)
    private var inProgressBooks: [Book]

    @Query(filter: BookLibraryReader.finishedPredicate, sort: BookLibraryReader.finishedSort)
    private var finishedBooks: [Book]

    @Query(sort: [SortDescriptor(\ReadingDay.date, order: .reverse)])
    private var readingDays: [ReadingDay]

    @Query(sort: [SortDescriptor(\ReadingSession.endedAt, order: .reverse)])
    private var readingSessions: [ReadingSession]

    @Query(sort: [SortDescriptor(\SessionRetrospective.createdAt, order: .reverse)])
    private var retrospectives: [SessionRetrospective]

    @State private var searchSheet: SearchSheet?

    init(
        onStartSession: ((Book) -> Void)? = nil,
        onShowAllCurrentlyReading: @escaping () -> Void = {}
    ) {
        self.onStartSession = onStartSession
        self.onShowAllCurrentlyReading = onShowAllCurrentlyReading
    }

    private enum SearchSheet: Identifiable {
        case entertainment, study, anyAttitude
        var id: String {
            switch self {
            case .entertainment: "entertainment"
            case .study: "study"
            case .anyAttitude: "any"
            }
        }
    }

    private var isLibraryEmpty: Bool {
        inProgressBooks.isEmpty && finishedBooks.isEmpty
    }

    private var entertainmentBook: Book? {
        inProgressBooks.first { $0.attitude == .entertainment }
    }

    private var studyBook: Book? {
        inProgressBooks.first { $0.attitude == .study }
    }

    private var weeklyFocusAverages: [FocusDifficultyReader.WeeklyAverage] {
        FocusDifficultyReader.lastFiveWeeks(
            sessions: readingSessions,
            retrospectives: retrospectives
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                GreetingSection()
                LiveCounterTile()
                WeekStripSection(days: readingDays)
                StatCardsSection(
                    days: readingDays,
                    sessions: readingSessions,
                    retrospectives: retrospectives
                )
                content
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.top, Theme.Spacing.base)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Palette.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $searchSheet) { sheet in
            switch sheet {
            case .entertainment: BookSearchView(presetAttitude: .entertainment)
            case .study: BookSearchView(presetAttitude: .study)
            case .anyAttitude: BookSearchView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLibraryEmpty {
            VStack(spacing: Theme.Spacing.md) {
                MascotEmptyTile(onAddTapped: { searchSheet = .anyAttitude })
                FocusDifficultyChartCard(weeks: weeklyFocusAverages)
                QuoteOfTheDayTile()
            }
        } else {
            VStack(spacing: Theme.Spacing.md) {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    EntertainmentBookTile(
                        book: entertainmentBook,
                        onStart: startSession,
                        onAddTapped: { searchSheet = .entertainment }
                    )
                    StudyBookTile(
                        book: studyBook,
                        onStart: startSession,
                        onAddTapped: { searchSheet = .study }
                    )
                }
                AllCurrentlyReadingEntry(
                    inProgressCount: inProgressBooks.count,
                    onTap: onShowAllCurrentlyReading
                )
                FocusDifficultyChartCard(weeks: weeklyFocusAverages)
                QuoteOfTheDayTile()
                if !finishedBooks.isEmpty {
                    BooksYearGoalCard(
                        booksRead: BookGoalReader.booksFinishedThisYear(from: finishedBooks),
                        yearlyGoal: max(1, ReadingGoalPreferences.annualBookTarget)
                    )
                }
                FinishedSection(books: finishedBooks)
            }
        }
    }

    private func startSession(_ book: Book) {
        if let onStartSession {
            onStartSession(book)
        } else {
            engine.stage(book: book)
        }
    }
}

#Preview("Full dashboard — seeded") {
    let container = CrawModelContainer.previewInMemory()
    SampleData.seed(into: ModelContext(container))
    return NavigationStack { HomeDashboardView() }
        .modelContainer(container)
        .environment(SessionEngine.shared)
}

#Preview("Empty library") {
    NavigationStack { HomeDashboardView() }
        .modelContainer(CrawModelContainer.previewInMemory())
        .environment(SessionEngine.shared)
}
