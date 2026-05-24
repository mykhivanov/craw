import Foundation

@MainActor
final class LiveActivityActionObserver {
    static let shared = LiveActivityActionObserver()

    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        for action in LiveActivityAction.allCases {
            CFNotificationCenterAddObserver(
                center,
                observer,
                { _, _, name, _, _ in
                    guard let raw = name?.rawValue as String? else { return }
                    DispatchQueue.main.async {
                        LiveActivityActionObserver.shared.handle(darwinName: raw)
                    }
                },
                action.darwinName as CFString,
                nil,
                .deliverImmediately
            )
        }
    }

    private func handle(darwinName: String) {
        guard let action = LiveActivityAction.allCases.first(where: { $0.darwinName == darwinName }) else { return }
        switch action {
        case .pause:
            SessionEngine.shared.pause()
        case .resume:
            SessionEngine.shared.resume()
        case .stopAndOpenApp:
            // Stop from lock screen: pause the timer so it stops counting while the
            // user unlocks. The user finalizes via the existing in-app Stop button
            // (which the SessionTimerView already presents while paused).
            if SessionEngine.shared.state == .running {
                SessionEngine.shared.pause()
            }
        }
    }
}
