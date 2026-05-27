import Foundation

enum ReadingGoalPreferences {
    private static let yearlyGoalRawKey = "CrawYearlyGoalRaw"
    private static let yearlyGoalTargetKey = "CrawYearlyGoalTarget"

    static let fallbackAnnualBookTarget = YearlyGoal.youTellMe.annualBookTarget

    static var annualBookTarget: Int {
        let storedTarget = UserDefaults.standard.integer(forKey: yearlyGoalTargetKey)
        guard storedTarget > 0 else {
            return fallbackAnnualBookTarget
        }
        return storedTarget
    }

    static var selectedYearlyGoal: YearlyGoal? {
        guard let rawValue = UserDefaults.standard.string(forKey: yearlyGoalRawKey) else {
            return nil
        }
        return YearlyGoal(rawValue: rawValue)
    }

    static func save(yearlyGoal: YearlyGoal) {
        UserDefaults.standard.set(yearlyGoal.rawValue, forKey: yearlyGoalRawKey)
        UserDefaults.standard.set(yearlyGoal.annualBookTarget, forKey: yearlyGoalTargetKey)
    }
}
