import SwiftData
import SwiftUI

private enum PostSessionStep: Equatable {
    case thoughts
    case quizLoading
    case quiz
    case quizUnavailable
    case retrospective
    case celebration
    case finished
}

struct PostSessionFlow: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    @State private var step: PostSessionStep = .thoughts
    @State private var pipeline: PostSessionPipeline?
    @State private var savedSession: ReadingSession?
    @State private var quizService = QuizService()
    @State private var generatedQuiz: GeneratedQuiz?
    @State private var streakBefore = 0
    @State private var streakAfter = 0

    var body: some View {
        Group {
            switch step {
            case .thoughts:
                ThoughtsPromptView(onContinue: handleThoughts)
            case .quizLoading:
                VStack(spacing: Theme.Spacing.base) {
                    ProgressView()
                    Text("Preparing your quiz…")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.canvas)
            case .quiz:
                if let quiz = generatedQuiz {
                    QuizView(quiz: quiz, onSubmit: handleQuizSubmit, onSkip: handleQuizSkip)
                } else {
                    Color.clear
                }
            case .quizUnavailable:
                QuizUnavailableView(onContinue: handleQuizUnavailable)
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
            if pipeline == nil {
                pipeline = PostSessionPipeline(context: modelContext)
            }
            if savedSession == nil {
                streakBefore = pipeline?.currentStreakSnapshot() ?? 0
                engine.beginSaving()
                savedSession = pipeline?.commit(engine)
                streakAfter = pipeline?.currentStreakSnapshot() ?? streakBefore
            }
        }
    }

    private func handleThoughts(_ texts: [String]) {
        if let bookID = engine.book?.id {
            pipeline?.saveThoughts(texts, for: bookID)
        }
        step = .quizLoading
        Task { await prepareQuiz() }
    }

    private func prepareQuiz() async {
        guard let book = engine.book, let session = savedSession else {
            step = .retrospective
            return
        }
        let pageEnd = engine.currentPage
        let pageStart = max(0, pageEnd - max(1, session.pagesRead))
        let result = await quizService.generate(
            bookTitle: book.title,
            bookAuthor: book.author,
            pageStart: pageStart,
            pageEnd: pageEnd
        )
        switch result {
        case let .success(quiz):
            generatedQuiz = quiz
            step = .quiz
        case .failure:
            step = .quizUnavailable
        }
    }

    private func handleQuizSubmit(answers: [Int?], reflection: String) {
        guard let quiz = generatedQuiz, let session = savedSession else { return }
        let outcome = quizService.grade(answers: answers, against: quiz)
        let state: VerificationState = switch outcome {
        case .verified: .verified
        case .failed: .failed
        }
        pipeline?.updateVerification(sessionID: session.id, to: state, reflectionText: reflection)
        step = .retrospective
    }

    private func handleQuizSkip() {
        if let session = savedSession {
            pipeline?.updateVerification(sessionID: session.id, to: .skipped)
        }
        step = .retrospective
    }

    private func handleQuizUnavailable() {
        if let session = savedSession {
            pipeline?.updateVerification(sessionID: session.id, to: .unavailable)
        }
        step = .retrospective
    }

    private func handleRetrospective(start: Int, focus: Int, enjoyment: Int) {
        if let session = savedSession {
            pipeline?.saveRetrospective(
                sessionID: session.id,
                startDifficulty: start,
                focusDifficulty: focus,
                enjoyment: enjoyment
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
