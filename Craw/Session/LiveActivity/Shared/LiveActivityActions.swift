import Foundation

enum LiveActivityAction: String, CaseIterable {
    case pause
    case resume
    case stopAndOpenApp

    nonisolated var darwinName: String {
        "com.mykhivanov.Craw.liveactivity.\(rawValue)"
    }
}

enum LiveActivityActions {
    nonisolated static func post(_ action: LiveActivityAction) {
        let name = CFNotificationName(rawValue: action.darwinName as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name,
            nil,
            nil,
            true
        )
    }
}
