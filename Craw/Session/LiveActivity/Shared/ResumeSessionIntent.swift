import AppIntents

struct ResumeSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume reading"
    static var description: IntentDescription? = IntentDescription("Resumes the paused reading timer.")

    func perform() async throws -> some IntentResult {
        LiveActivityActions.post(.resume)
        return .result()
    }
}
