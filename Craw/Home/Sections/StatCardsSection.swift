import SwiftUI

struct StatCardsSection: View {
    let days: [ReadingDay]
    let streakThreshold: Int

    init(days: [ReadingDay], streakThreshold: Int = 7) {
        self.days = days
        self.streakThreshold = streakThreshold
    }

    private var todayMetrics: ReadingActivityReader.DayMetrics {
        ReadingActivityReader.today(from: days)
    }

    private var pagesDelta: ReadingActivityReader.PagesDelta {
        ReadingActivityReader.pagesDeltaVsYesterday(from: days)
    }

    private var streak: Int {
        ReadingActivityReader.currentStreak(from: days)
    }

    private var calendarWeek: [ReadingActivityReader.CalendarWeekDay] {
        ReadingActivityReader.currentCalendarWeek(from: days)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            TodaysPagesCard(metrics: todayMetrics, delta: pagesDelta)
            StreakCard(
                streak: streak,
                calendarWeek: calendarWeek,
                threshold: streakThreshold
            )
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

struct TodaysPagesCard: View {
    let metrics: ReadingActivityReader.DayMetrics
    let delta: ReadingActivityReader.PagesDelta

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Today")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("\(metrics.pagesRead)")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                Text("pages")
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

#Preview("Streak card — both regimes") {
    let calendar = Calendar.autoupdatingCurrent
    let today = calendar.startOfDay(for: .now)
    let week = (0..<7).compactMap { offset -> ReadingActivityReader.CalendarWeekDay? in
        guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
        return ReadingActivityReader.CalendarWeekDay(
            date: date,
            weekdaySymbol: ["S", "M", "T", "W", "T", "F", "S"][offset],
            hasActivity: offset % 2 == 0,
            isToday: offset == 0
        )
    }
    return VStack(spacing: 16) {
        HStack(spacing: 12) {
            TodaysPagesCard(
                metrics: .init(date: today, minutesRead: 45, pagesRead: 30),
                delta: .init(todayPages: 30, kind: .percentChange(50))
            )
            StreakCard(streak: 3, calendarWeek: week, threshold: 7)
        }
        HStack(spacing: 12) {
            TodaysPagesCard(
                metrics: .init(date: today, minutesRead: 60, pagesRead: 22),
                delta: .init(todayPages: 22, kind: .increaseFromZero)
            )
            StreakCard(streak: 12, calendarWeek: week, threshold: 7)
        }
    }
    .padding()
}
