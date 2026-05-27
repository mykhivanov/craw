import SwiftUI

struct GreetingSection: View {
    let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    var body: some View {
        GreetingHeader(now: now)
    }
}

struct GreetingHeader: View {
    let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Image("mascotCraw")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            Text("Good \(partOfDay)")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .tileCard()
    }

    private var partOfDay: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
        switch hour {
        case 4..<12: return "morning"
        case 12..<18: return "afternoon"
        default: return "evening"
        }
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
