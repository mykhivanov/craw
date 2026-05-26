import SwiftData
import SwiftUI

private enum PostSessionStep: Equatable {
    case quizSections
    case quizQuestions(sectionOrPage: String?)
    case quizFeedback(mark: Int)
    case retrospective
    case celebration
    case finished
}

struct PostSessionFlow: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    @State private var step: PostSessionStep = .retrospective
    @State private var pipeline: PostSessionPipeline?
    @State private var savedSession: ReadingSession?
    @State private var streakBefore = 0
    @State private var streakAfter = 0
    @State private var didBootstrap = false

    var body: some View {
        Group {
            switch step {
            case .quizSections:
                QuizSectionsView(
                    bookName: engine.book?.title ?? "",
                    onPick: handlePickedSectionOrPage,
                    onSkip: handleSectionSkip,
                    onError: handleSectionSkip
                )
            case let .quizQuestions(sectionOrPage):
                QuizQuestionsView(
                    bookName: engine.book?.title ?? "",
                    sectionOrPage: sectionOrPage,
                    onGrade: { mark in handleGrade(mark: mark, sectionOrPage: sectionOrPage) },
                    onSkip: handleQuestionsSkip,
                    onError: handleQuestionsSkip
                )
            case let .quizFeedback(mark):
                QuizFeedbackView(mark: mark, onContinue: { step = .retrospective })
            case .retrospective:
                RetrospectiveView(onSubmit: handleRetrospective)
            case .celebration:
                StreakCelebrationView(streakDays: streakAfter, onContinue: handleCelebration)
            case .finished:
                Color.clear.task { engine.finish() }
            }
        }
        .background(Theme.Palette.canvas)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            if pipeline == nil {
                pipeline = PostSessionPipeline(context: modelContext)
            }
            streakBefore = pipeline?.currentStreakSnapshot() ?? 0
            engine.beginSaving()
            savedSession = pipeline?.commit(engine)
            streakAfter = pipeline?.currentStreakSnapshot() ?? streakBefore
            step = initialStep()
        }
    }

    private func initialStep() -> PostSessionStep {
        let attitude = engine.book?.attitude ?? .entertainment
        guard attitude == .study else { return .retrospective }
        if engine.endedAsBookFinished {
            // Finished-mid-session study book: skip section picker, jump to questions.
            return .quizQuestions(sectionOrPage: nil)
        }
        return .quizSections
    }

    private func handlePickedSectionOrPage(_ sectionOrPage: String) {
        step = .quizQuestions(sectionOrPage: sectionOrPage)
    }

    private func handleSectionSkip() {
        step = .retrospective
    }

    private func handleQuestionsSkip() {
        step = .retrospective
    }

    private func handleGrade(mark: Int, sectionOrPage: String?) {
        guard let session = savedSession else {
            step = .retrospective
            return
        }
        pipeline?.updateQuizResult(
            sessionID: session.id,
            sectionOrPageHint: sectionOrPage,
            mark: mark
        )
        step = .quizFeedback(mark: mark)
    }

    private func handleRetrospective(focusDifficulty: Int) {
        if let session = savedSession {
            pipeline?.saveRetrospective(
                sessionID: session.id,
                focusDifficulty: focusDifficulty
            )
        }
        if streakBefore == 6, streakAfter == 7 {
            step = .celebration
        } else {
            step = .finished
        }
    }

    private func handleCelebration() {
        step = .finished
    }
}
