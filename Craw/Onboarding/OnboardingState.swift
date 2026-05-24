import Foundation
import Observation
import UserNotifications

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case nextLevelPartner
    case replaceDoomScrolling
    case habit
    case smarter
    case consistent
    case track

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .nextLevelPartner: "Become worthy of next-level love"
        case .habit: "Build a daily reading habit"
        case .smarter: "Read to get sharper"
        case .consistent: "Read consistently every week"
        case .track: "Track progress and streaks"
        case .replaceDoomScrolling: "Replace scrolling with pages"
        }
    }

    var subtitle: String {
        switch self {
        case .nextLevelPartner: "Grow into the partner you want to attract — sharper, grounded, and in your own league."
        case .habit: "Turn a small daily minimum into an automatic routine."
        case .smarter: "Capture ideas, quotes, and takeaways you can use later."
        case .consistent: "Keep momentum even when your week gets busy."
        case .track: "See pages, streaks, sessions, and progress compound."
        case .replaceDoomScrolling: "Use downtime for something that leaves you better."
        }
    }

    var icon: String {
        switch self {
        case .nextLevelPartner: "heart.circle.fill"
        case .habit: "flame.fill"
        case .smarter: "brain.head.profile"
        case .consistent: "calendar.badge.checkmark"
        case .track: "chart.line.uptrend.xyaxis"
        case .replaceDoomScrolling: "iphone.slash"
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable, Hashable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var id: Int {
        rawValue
    }

    var shortLabel: String {
        switch self {
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "T"
        case .friday: "F"
        case .saturday: "S"
        case .sunday: "S"
        }
    }

    var label: String {
        switch self {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }

    static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
}

enum YearlyGoal: String, CaseIterable, Identifiable {
    case youTellMe
    case oneToSix
    case sevenToTwelve
    case twelvePlus

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .youTellMe: "Recommend a pace for me"
        case .oneToSix: "1–6 books"
        case .sevenToTwelve: "7–12 books"
        case .twelvePlus: "12+ books"
        }
    }

    var subtitle: String {
        switch self {
        case .youTellMe: "Start realistic and adjust after your first week."
        case .oneToSix: "A light plan for building consistency first."
        case .sevenToTwelve: "A steady monthly rhythm with room for life."
        case .twelvePlus: "An ambitious pace for a serious reading year."
        }
    }

    var icon: String {
        switch self {
        case .youTellMe: "sparkles"
        case .oneToSix: "leaf.fill"
        case .sevenToTwelve: "target"
        case .twelvePlus: "bolt.fill"
        }
    }
}

@Observable
@MainActor
final class OnboardingState {
    static let stepCount = 6

    var stepIndex: Int = 0
    var selectedGoals: Set<OnboardingGoal> = []
    var dailyReadingMinutes: Int = 15
    var readingWeekdays: Set<Weekday> = Weekday.weekdays
    var reminderTime: DateComponents = .init(hour: 8, minute: 0)
    var yearlyGoal: YearlyGoal?
    var wantsReminders: Bool = false
    var reminderAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isCompleted: Bool = false

    static var shouldSkipFromLaunchArgs: Bool {
        #if DEBUG
            return UserDefaults.standard.bool(forKey: "CrawSkipOnboarding")
        #else
            return false
        #endif
    }

    func advance() {
        guard stepIndex < Self.stepCount - 1 else { return }
        stepIndex += 1
    }

    func complete() {
        isCompleted = true
    }
}
