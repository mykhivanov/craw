import AppIntents

struct PauseSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause reading"
    static var description: IntentDescription? = IntentDescription("Pauses the active reading timer.")

    func perform() async throws -> some IntentResult {
        LiveActivityActions.post(.pause)
        return .result()
    }
}
