import Foundation

protocol LiveCounterProvider: AnyObject {
    func currentValue(at date: Date) -> Int
}

final class DeterministicLiveCounter: LiveCounterProvider {
    private static let seedKey = "CrawLiveCounterSeed"
    private static let base = 1000.0
    private static let amplitude = 8000.0
    private static let peakHour = 20.0

    private let offset: Double
    private var lastValue: Int?

    init() {
        let stored = UserDefaults.standard.double(forKey: Self.seedKey)
        if stored == 0 {
            let new = Double.random(in: 0..<(2 * .pi))
            UserDefaults.standard.set(new, forKey: Self.seedKey)
            offset = new
        } else {
            offset = stored
        }
    }

    func currentValue(at date: Date) -> Int {
        let raw = computeRaw(at: date)
        if let last = lastValue {
            let maxDelta = max(1, Int((Double(last) * 0.05).rounded()))
            let clamped = max(last - maxDelta, min(last + maxDelta, raw))
            lastValue = clamped
            return clamped
        }
        lastValue = raw
        return raw
    }

    private func computeRaw(at date: Date) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hourFrac = Double(comps.hour ?? 0) / 24.0
            + Double(comps.minute ?? 0) / 1440.0
            + Double(comps.second ?? 0) / 86400.0
        let peakFrac = Self.peakHour / 24.0
        let phase = (hourFrac - peakFrac) * 2 * .pi
        let curve = (cos(phase) + 1) / 2
        let noise = sin(date.timeIntervalSince1970 * 0.01 + offset) * 0.05
        return Int(Self.base + Self.amplitude * curve * (1 + noise))
    }
}
