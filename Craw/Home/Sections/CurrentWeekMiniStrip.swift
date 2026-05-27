import SwiftUI

struct CurrentWeekMiniStrip: View {
    let week: [ReadingActivityReader.CalendarWeekDay]

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(week, id: \.date) { day in
                MiniDayMarker(day: day)
            }
        }
    }
}

private struct MiniDayMarker: View {
    let day: ReadingActivityReader.CalendarWeekDay

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(day.hasMetGoal ? Theme.Palette.rausch : Theme.Palette.hairline)
                .frame(width: 8, height: 8)
            Text(day.weekdaySymbol)
                .font(.system(size: 9, weight: day.isToday ? .bold : .regular))
                .foregroundStyle(day.isToday ? Theme.Palette.ink : Theme.Palette.muted)
        }
    }
}
