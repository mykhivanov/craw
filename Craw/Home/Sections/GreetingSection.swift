import SwiftUI

struct GreetingSection: View {
    let now: Date
    let counterProvider: LiveCounterProvider

    init(now: Date = .now, counterProvider: LiveCounterProvider = DeterministicLiveCounter()) {
        self.now = now
        self.counterProvider = counterProvider
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            GreetingHeader(now: now)
            LiveCounterLabel(provider: counterProvider)
        }
    }
}

struct GreetingHeader: View {
    let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    var body: some View {
        Text("Good \(partOfDay), \(weekdayName)")
            .font(Theme.Typography.displayLg)
            .foregroundStyle(Theme.Palette.ink)
    }

    private var partOfDay: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
        switch hour {
        case 4..<12: return "morning"
        case 12..<18: return "afternoon"
        default: return "evening"
        }
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "EEEE"
        return formatter.string(from: now)
    }
}

struct LiveCounterLabel: View {
    let provider: LiveCounterProvider

    var body: some View {
        TimelineView(.periodic(from: .now, by: 8)) { context in
            Text("\(provider.currentValue(at: context.date).formatted()) people reading now")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
        }
    }
}
