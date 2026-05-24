import AppIntents

struct StopFromLockScreenIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop reading"
    static var description: IntentDescription? =
        IntentDescription("Pauses the timer and opens Craw to finalize the session.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        LiveActivityActions.post(.stopAndOpenApp)
        return .result()
    }
}
