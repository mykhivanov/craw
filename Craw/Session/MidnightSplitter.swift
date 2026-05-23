import Foundation

enum MidnightSplitter {
    struct Bucket: Equatable {
        let date: Date
        let seconds: Int
    }

    static func split(
        startedAt: Date,
        endedAt: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Bucket] {
        guard endedAt > startedAt else { return [] }
        var buckets: [Bucket] = []
        var cursor = startedAt
        while cursor < endedAt {
            let dayStart = calendar.startOfDay(for: cursor)
            let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? endedAt
            let bucketEnd = min(nextDayStart, endedAt)
            let seconds = Int(bucketEnd.timeIntervalSince(cursor))
            if seconds > 0 {
                buckets.append(Bucket(date: dayStart, seconds: seconds))
            }
            cursor = bucketEnd
        }
        return buckets
    }
}
