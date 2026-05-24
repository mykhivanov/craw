import Foundation
import Observation

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case habit
    case smarter
    case consistent
    case track
    case replaceDoomScrolling

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .habit: "Make reading my new habit"
        case .smarter: "Make me smarter"
        case .consistent: "Make me reading consistently"
        case .track: "Track progress and statistics"
        case .replaceDoomScrolling: "Replace doom scrolling reels"
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
        case .youTellMe: "You tell me"
        case .oneToSix: "1–6 books"
        case .sevenToTwelve: "7–12 books"
        case .twelvePlus: "12+ books"
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
