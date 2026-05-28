import Foundation

// MARK: - Daily-stats write

struct DailyStatsPayload: Codable, Equatable {
    let date: String // yyyy-MM-dd (local day)
    let minutesRead: Int
    let sessions: Int
    let avgFocusDifficulty: Double?
    let avgQuizMark: Double?
    let studyShare: Double
    let dailyGoalMin: Int?
    let goalHit: Bool?
    let booksFinished: Int
    let quotesCaptured: Int

    enum CodingKeys: String, CodingKey {
        case date
        case minutesRead = "minutes_read"
        case sessions
        case avgFocusDifficulty = "avg_focus_difficulty"
        case avgQuizMark = "avg_quiz_mark"
        case studyShare = "study_share"
        case dailyGoalMin = "daily_goal_min"
        case goalHit = "goal_hit"
        case booksFinished = "books_finished"
        case quotesCaptured = "quotes_captured"
    }
}

struct DailyStatsAck: Decodable {
    let ok: Bool
}

// MARK: - Stats read

enum StatsPeriod: String, CaseIterable, Codable {
    case week
    case month
    case year
    case lifetime

    var label: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        case .lifetime: "Lifetime"
        }
    }
}

struct StatsBundle: Decodable {
    let period: StatsPeriod
    let generatedAt: Date
    let tiles: TileSet
    let trends: TrendSet

    enum CodingKeys: String, CodingKey {
        case period
        case generatedAt = "generated_at"
        case tiles
        case trends
    }
}

struct TileSet: Decodable {
    let focusDifficulty: Tile
    let goalHitRate: Tile
    let comprehension: Tile
    let avgSessionMin: Tile
    let sessionsPerWeek: Tile
    let currentStreak: Tile
    let fullWeekStreaks: Tile
    let minutes: Tile
    let booksFinished: Tile
    let sessionsTotal: Tile
    let studyShare: Tile
    let finishRate: Tile

    enum CodingKeys: String, CodingKey {
        case focusDifficulty = "focus_difficulty"
        case goalHitRate = "goal_hit_rate"
        case comprehension
        case avgSessionMin = "avg_session_min"
        case sessionsPerWeek = "sessions_per_week"
        case currentStreak = "current_streak"
        case fullWeekStreaks = "full_week_streaks"
        case minutes
        case booksFinished = "books_finished"
        case sessionsTotal = "sessions_total"
        case studyShare = "study_share"
        case finishRate = "finish_rate"
    }
}

struct Tile: Decodable {
    let value: Double?
    let unit: String
    let trend: TileTrend?
    let cohort: TileCohort?
}

struct TileTrend: Decodable {
    let priorValue: Double?
    let delta: Double
    let deltaPct: Double?

    enum CodingKeys: String, CodingKey {
        case priorValue = "prior_value"
        case delta
        case deltaPct = "delta_pct"
    }
}

struct TileCohort: Decodable {
    let percentile: Int
    let median: Double
    let source: String // "synthetic_v1" | "hybrid" | "craw_users"
}

struct TrendSet: Decodable {
    let focusDifficulty12w: [TrendPoint]
    let minutesPerWeek12w: [TrendPoint]
    let comprehensionLast20: [TrendPoint]

    enum CodingKeys: String, CodingKey {
        case focusDifficulty12w = "focus_difficulty_12w"
        case minutesPerWeek12w = "minutes_per_week_12w"
        case comprehensionLast20 = "comprehension_last_20"
    }
}

struct TrendPoint: Decodable, Identifiable {
    let at: Date
    let value: Double?

    var id: Date {
        at
    }
}

// MARK: - Methodology

struct MethodologyDocument: Decodable {
    let markdown: String
}
