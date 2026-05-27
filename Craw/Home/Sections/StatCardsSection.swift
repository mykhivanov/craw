import SwiftUI

struct StatCardsSection: View {
    let days: [ReadingDay]
    let sessions: [ReadingSession]
    let retrospectives: [SessionRetrospective]
    let streakThreshold: Int

    init(
        days: [ReadingDay],
        sessions: [ReadingSession] = [],
        retrospectives: [SessionRetrospective] = [],
        streakThreshold: Int = 7
    ) {
        self.days = days
        self.sessions = sessions
        self.retrospectives = retrospectives
        self.streakThreshold = streakThreshold
    }

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    private var todayMetrics: ReadingActivityReader.DayMetrics {
        ReadingActivityReader.today(from: days)
    }

    private var minutesDelta: ReadingActivityReader.MinutesDelta {
        ReadingActivityReader.minutesDeltaVsYesterday(from: days)
    }

    private var streak: Int {
        ReadingActivityReader.currentStreak(from: days)
    }

    private var calendarWeek: [ReadingActivityReader.CalendarWeekDay] {
        ReadingActivityReader.currentCalendarWeek(from: days)
    }

    private var fullGoalWeeksCount: Int {
        ReadingActivityReader.fullGoalWeeksCount(from: days)
    }

    private var currentFocusAverage: Double? {
        FocusDifficultyReader.currentWeekAverage(
            sessions: sessions,
            retrospectives: retrospectives
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
            TodaysMinutesCard(metrics: todayMetrics, delta: minutesDelta)
            StreakCard(
                streak: streak,
                calendarWeek: calendarWeek,
                threshold: streakThreshold
            )
            FullWeekReadingStreakCard(count: fullGoalWeeksCount)
            CurrentWeekFocusDifficultyCard(average: currentFocusAverage)
        }
    }
}

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.base)
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

private extension View {
    func crawCard() -> some View {
        modifier(CardBackground())
    }
}

struct TodaysMinutesCard: View {
    let metrics: ReadingActivityReader.DayMetrics
    let delta: ReadingActivityReader.MinutesDelta

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Today")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("\(metrics.minutesRead)")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                Text("min")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            deltaLabel
        }
        .crawCard()
    }

    @ViewBuilder
    private var deltaLabel: some View {
        switch delta.kind {
        case let .percentChange(pct):
            let isUp = pct >= 0
            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                Text(String(format: "%+.0f%%", pct))
                    .font(Theme.Typography.badge)
            }
            .foregroundStyle(isUp ? Theme.Palette.trendUp : Theme.Palette.trendDown)
        case .increaseFromZero:
            HStack(spacing: 2) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                Text("new")
                    .font(Theme.Typography.badge)
            }
            .foregroundStyle(Theme.Palette.trendUp)
        case .unchangedZero:
            Text("no change")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.mutedSoft)
        }
    }
}

struct StreakCard: View {
    let streak: Int
    let calendarWeek: [ReadingActivityReader.CalendarWeekDay]
    let threshold: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Streak")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            if streak >= threshold {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    CurrentWeekMiniStrip(week: calendarWeek)
                    Text("\(streak) day streak")
                        .font(Theme.Typography.titleSm)
                        .foregroundStyle(Theme.Palette.rausch)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text("\(streak)")
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(streak == 1 ? "day" : "days")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Spacer().frame(height: 18)
            }
        }
        .crawCard()
    }
}

struct FullWeekReadingStreakCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Full week streak")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("\(count)")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                Text(count == 1 ? "week" : "weeks")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            Text("Sun-Sat goals hit")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.mutedSoft)
        }
        .crawCard()
    }
}

struct CurrentWeekFocusDifficultyCard: View {
    let average: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Focus difficulty")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            if let average {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text(String(format: "%.1f", average))
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("/ 5")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Text("This week avg")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            } else {
                Text("No focus data")
                    .font(Theme.Typography.titleSm)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Finish a session to rate it.")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }
        }
        .crawCard()
    }
}

struct BooksYearGoalCard: View {
    let booksRead: Int
    let yearlyGoal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Books this year")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            if booksRead == 0 {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text("\(yearlyGoal)")
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("book goal")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Text("No books finished yet")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text("\(booksRead)")
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("/ \(yearlyGoal)")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Text("books read / goal")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }
        }
        .crawCard()
    }
}

struct FocusDifficultyChartCard: View {
    let weeks: [FocusDifficultyReader.WeeklyAverage]

    private var hasData: Bool {
        weeks.contains { $0.average != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Focus trend")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                Spacer()
                Text("Last 5 weeks")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }

            FocusDifficultySparkline(weeks: weeks, isPlaceholder: !hasData)
                .frame(height: 96)

            HStack {
                ForEach(weeks) { week in
                    Text(weekLabel(for: week.weekStart))
                        .font(Theme.Typography.badge)
                        .foregroundStyle(Theme.Palette.mutedSoft)
                        .frame(maxWidth: .infinity)
                }
            }

            if !hasData {
                Text("No focus ratings yet")
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }
        }
        .crawCard()
    }

    private func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

private struct FocusDifficultySparkline: View {
    let weeks: [FocusDifficultyReader.WeeklyAverage]
    let isPlaceholder: Bool

    private var placeholderValues: [Double] {
        [2.0, 2.8, 2.4, 3.2, 2.7]
    }

    var body: some View {
        GeometryReader { proxy in
            let segments = chartSegments(size: proxy.size)
            ZStack {
                if let plateau = segments.plateau {
                    Path { path in
                        path.move(to: plateau.start)
                        path.addLine(to: plateau.end)
                    }
                    .stroke(
                        Theme.Palette.hairline,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                }

                Path { path in
                    guard let first = segments.points.first else { return }
                    path.move(to: first)
                    for point in segments.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    isPlaceholder ? Theme.Palette.hairline : Theme.Palette.rausch,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                ForEach(segments.points.indices, id: \.self) { index in
                    Circle()
                        .fill(isPlaceholder ? Theme.Palette.hairline : Theme.Palette.rausch)
                        .frame(width: 7, height: 7)
                        .position(segments.points[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private struct ChartSegments {
        let points: [CGPoint]
        let plateau: (start: CGPoint, end: CGPoint)?
    }

    private func chartSegments(size: CGSize) -> ChartSegments {
        let values: [Double?] = if isPlaceholder {
            placeholderValues.map { Optional($0) }
        } else {
            weeks.map(\.average)
        }

        let points: [CGPoint] = values.enumerated().compactMap { index, value -> CGPoint? in
            guard let value else { return nil }
            let x = values.count <= 1 ? size.width / 2 : CGFloat(index) / CGFloat(values.count - 1) * size.width
            let clamped = min(5.0, max(1.0, value))
            let y = size.height - CGFloat((clamped - 1.0) / 4.0) * size.height
            return CGPoint(x: x, y: y)
        }

        let firstDataIndex = values.firstIndex(where: { $0 != nil }) ?? 0
        let plateau: (start: CGPoint, end: CGPoint)? = if !isPlaceholder, firstDataIndex > 0,
                                                          let firstPoint = points.first
        {
            (CGPoint(x: 0, y: firstPoint.y), firstPoint)
        } else {
            nil
        }

        return ChartSegments(points: points, plateau: plateau)
    }
}
