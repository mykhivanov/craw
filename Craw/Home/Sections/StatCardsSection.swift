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

    private var minutesDelta: ReadingActivityReader.MinutesDelta {
        ReadingActivityReader.minutesDeltaVsYesterday(from: days)
    }

    private var streak: Int {
        ReadingActivityReader.currentStreak(from: days)
    }

    private var calendarWeek: [ReadingActivityReader.CalendarWeekDay] {
        ReadingActivityReader.currentCalendarWeek(from: days)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            TodaysMinutesCard(metrics: todayMetrics, delta: minutesDelta)
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
