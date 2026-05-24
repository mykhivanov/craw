import Foundation

final class CommunityActivityCounter: LiveCounterProvider {
    private static let seedKey = "CrawCommunityCounterSeed"
    private static let center = 200
    private static let lowerBound = 180
    private static let upperBound = 220
    private static let amplitude = 15.0
    private static let periodSeconds = 30.0
    private static let maxDelta = 5

    private let phase: Double
    private var lastValue: Int?

    init() {
        let stored = UserDefaults.standard.double(forKey: Self.seedKey)
        if stored == 0 {
            let new = Double.random(in: 0..<(2 * .pi))
            UserDefaults.standard.set(new, forKey: Self.seedKey)
            phase = new
        } else {
            phase = stored
        }
    }

    func currentValue(at date: Date) -> Int {
        let t = date.timeIntervalSince1970
        let curve = sin((t - phase) / Self.periodSeconds)
        let jitter = Int.random(in: -3...3)
        let raw = Self.center + Int((Self.amplitude * curve).rounded()) + jitter
        let clamped = clampStep(raw)
        lastValue = clamped
        return clamped
    }

    private func clampStep(_ raw: Int) -> Int {
        guard let last = lastValue else {
            return clampRange(raw)
        }
        let bounded = max(last - Self.maxDelta, min(last + Self.maxDelta, raw))
        return clampRange(bounded)
    }

    private func clampRange(_ value: Int) -> Int {
        max(Self.lowerBound, min(Self.upperBound, value))
    }
}
