import Foundation

enum ReadingGoals {
    /// Daily reading-time goal in minutes. Hardcoded until `add-goals-schedule`
    /// makes this user-configurable; single source of truth so the future change
    /// has one symbol to replace.
    static let dailyMinutes: Int = 30
}
