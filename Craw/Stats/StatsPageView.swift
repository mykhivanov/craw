import SwiftUI

struct StatsPageView: View {
    @Bindable var viewModel: StatsViewModel
    let backfill: StatsBackfillStore
    let onTileTap: (StatTileSelection) -> Void
    let onMethodologyTap: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    private let pairColumns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    periodSelector
                    contentForState
                    methodologyLink
                }
                .padding(.horizontal, Theme.Spacing.base)
                .padding(.vertical, Theme.Spacing.base)
            }
            .background(Theme.Palette.canvas)

            if case .running = backfill.state {
                StatsBackfillOverlay(state: backfill.state)
            }
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }

    private var periodSelector: some View {
        Picker("Period", selection: Binding(
            get: { viewModel.period },
            set: { viewModel.selectPeriod($0) }
        )) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingPlaceholder
        case let .loaded(bundle):
            loadedContent(bundle)
        case .subscriptionRequired:
            inlineError("A subscription is required to view stats.")
        case let .error(message):
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                inlineError(message)
                Button {
                    viewModel.reload()
                } label: {
                    Text("Try again")
                        .font(Theme.Typography.buttonSm)
                        .foregroundStyle(Theme.Palette.rausch)
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(Theme.Palette.rausch)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Theme.Spacing.xl)
        }
    }

    private func inlineError(_ message: String) -> some View {
        Text(message)
            .font(Theme.Typography.bodyMd)
            .foregroundStyle(Theme.Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.Spacing.lg)
    }

    @ViewBuilder
    private func loadedContent(_ bundle: StatsBundle) -> some View {
        heroSection(bundle.tiles)
        habitSection(bundle.tiles)
        volumeSection(bundle.tiles)
        compositionSection(bundle.tiles)
        trendSection(bundle.trends)
    }

    @ViewBuilder
    private func heroSection(_ tiles: TileSet) -> some View {
        sectionHeader("Focus & growth")
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
            tappableTile(
                .focusDifficulty,
                title: "Focus difficulty",
                tile: tiles.focusDifficulty,
                emptyState: "Rate sessions to track focus.",
                isHero: true
            )
            tappableTile(
                .goalHitRate,
                title: "Goal hit rate",
                tile: tiles.goalHitRate,
                emptyState: "Set your daily goal",
                isHero: true
            )
            tappableTile(
                .comprehension,
                title: "Comprehension",
                tile: tiles.comprehension,
                emptyState: "Take a quiz to track this.",
                isHero: true
            )
        }
    }

    @ViewBuilder
    private func habitSection(_ tiles: TileSet) -> some View {
        sectionHeader("Habit")
        LazyVGrid(columns: pairColumns, alignment: .leading, spacing: Theme.Spacing.md) {
            tappableTile(
                .avgSessionMin,
                title: "Avg session",
                tile: tiles.avgSessionMin,
                emptyState: "Start a session to track this."
            )
            tappableTile(
                .sessionsPerWeek,
                title: "Sessions / week",
                tile: tiles.sessionsPerWeek,
                emptyState: "No sessions yet."
            )
            tappableTile(
                .currentStreak,
                title: "Current streak",
                tile: tiles.currentStreak,
                emptyState: "Read today to start a streak."
            )
            tappableTile(
                .fullWeekStreaks,
                title: "Full-week streaks",
                tile: tiles.fullWeekStreaks,
                emptyState: "Hit your goal Sun–Sat to count one."
            )
        }
    }

    @ViewBuilder
    private func volumeSection(_ tiles: TileSet) -> some View {
        sectionHeader("Volume")
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
            tappableTile(.minutes, title: "Minutes", tile: tiles.minutes, emptyState: "No minutes yet.")
            tappableTile(
                .booksFinished,
                title: "Books finished",
                tile: tiles.booksFinished,
                emptyState: "Finish a book to track this."
            )
            tappableTile(
                .sessionsTotal,
                title: "Sessions total",
                tile: tiles.sessionsTotal,
                emptyState: "No sessions yet."
            )
        }
    }

    @ViewBuilder
    private func compositionSection(_ tiles: TileSet) -> some View {
        sectionHeader("Composition")
        LazyVGrid(columns: pairColumns, alignment: .leading, spacing: Theme.Spacing.md) {
            tappableTile(
                .studyShare,
                title: "Study share",
                tile: tiles.studyShare,
                emptyState: "Mark books as study or entertainment."
            )
            tappableTile(
                .finishRate,
                title: "Finish rate",
                tile: tiles.finishRate,
                emptyState: "Finish a book to track this."
            )
        }
    }

    @ViewBuilder
    private func trendSection(_ trends: TrendSet) -> some View {
        sectionHeader("Trends")
        VStack(spacing: Theme.Spacing.md) {
            StatsTrendCard(title: "Focus difficulty", subtitle: "Last 12 weeks", points: trends.focusDifficulty12w)
            StatsTrendCard(title: "Minutes per week", subtitle: "Last 12 weeks", points: trends.minutesPerWeek12w)
            StatsTrendCard(title: "Comprehension", subtitle: "Last 20 sessions", points: trends.comprehensionLast20)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.titleSm)
            .foregroundStyle(Theme.Palette.ink)
            .padding(.top, Theme.Spacing.sm)
    }

    private func tappableTile(
        _ selection: StatTileSelection,
        title: String,
        tile: Tile,
        emptyState: String,
        isHero: Bool = false
    ) -> some View {
        Button {
            onTileTap(selection)
        } label: {
            StatTile(title: title, tile: tile, emptyStateMessage: emptyState, isHero: isHero)
        }
        .buttonStyle(.plain)
    }

    private var methodologyLink: some View {
        Button {
            onMethodologyTap()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text("How we compare you")
                    .font(Theme.Typography.buttonSm)
                    .foregroundStyle(Theme.Palette.muted)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

enum StatTileSelection: Hashable {
    case focusDifficulty
    case goalHitRate
    case comprehension
    case avgSessionMin
    case sessionsPerWeek
    case currentStreak
    case fullWeekStreaks
    case minutes
    case booksFinished
    case sessionsTotal
    case studyShare
    case finishRate

    var title: String {
        switch self {
        case .focusDifficulty: "Focus difficulty"
        case .goalHitRate: "Goal hit rate"
        case .comprehension: "Comprehension"
        case .avgSessionMin: "Avg session"
        case .sessionsPerWeek: "Sessions / week"
        case .currentStreak: "Current streak"
        case .fullWeekStreaks: "Full-week streaks"
        case .minutes: "Minutes"
        case .booksFinished: "Books finished"
        case .sessionsTotal: "Sessions total"
        case .studyShare: "Study share"
        case .finishRate: "Finish rate"
        }
    }

    func tile(from set: TileSet) -> Tile {
        switch self {
        case .focusDifficulty: set.focusDifficulty
        case .goalHitRate: set.goalHitRate
        case .comprehension: set.comprehension
        case .avgSessionMin: set.avgSessionMin
        case .sessionsPerWeek: set.sessionsPerWeek
        case .currentStreak: set.currentStreak
        case .fullWeekStreaks: set.fullWeekStreaks
        case .minutes: set.minutes
        case .booksFinished: set.booksFinished
        case .sessionsTotal: set.sessionsTotal
        case .studyShare: set.studyShare
        case .finishRate: set.finishRate
        }
    }
}
