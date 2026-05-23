import Foundation
import FoundationModels

enum QuizServiceError: Error {
    case modelUnavailable
    case generationFailed(Error)
    case validationFailed(QuizValidationFailure)
}

@MainActor
final class QuizService {
    enum GradedOutcome {
        case verified(correctCount: Int)
        case failed(correctCount: Int)
    }

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func generate(
        bookTitle: String,
        bookAuthor: String,
        pageStart: Int,
        pageEnd: Int
    ) async -> Result<GeneratedQuiz, QuizServiceError> {
        guard SystemLanguageModel.default.isAvailable else {
            return .failure(.modelUnavailable)
        }
        let session = LanguageModelSession(instructions: Self.instructions)
        let prompt = Self.makePrompt(
            bookTitle: bookTitle,
            bookAuthor: bookAuthor,
            pageStart: pageStart,
            pageEnd: pageEnd
        )
        do {
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedQuiz.self,
                options: GenerationOptions(temperature: 0.2)
            )
            switch QuizValidator.validate(response.content) {
            case let .success(quiz):
                return .success(quiz)
            case let .failure(failure):
                return .failure(.validationFailed(failure))
            }
        } catch {
            return .failure(.generationFailed(error))
        }
    }

    func grade(answers: [Int?], against quiz: GeneratedQuiz) -> GradedOutcome {
        let correctCount = zip(answers, quiz.questions).reduce(into: 0) { count, pair in
            let (chosen, question) = pair
            if let chosen, chosen == question.correctIndex {
                count += 1
            }
        }
        if correctCount >= Theme.Quiz.passThreshold {
            return .verified(correctCount: correctCount)
        }
        return .failed(correctCount: correctCount)
    }

    private static let instructions = """
    You write short comprehension quizzes for books the user just finished reading a section of. \
    Each quiz contains exactly four multiple-choice questions and one open-ended reflection prompt. \
    Multiple-choice questions must be answerable from the specific page range cited in the prompt. \
    Each question must have four distinct options and exactly one correct answer. \
    Keep questions concrete and avoid trivia about the author or unrelated sections of the book.
    """

    private static func makePrompt(
        bookTitle: String,
        bookAuthor: String,
        pageStart: Int,
        pageEnd: Int
    ) -> String {
        """
        Write a comprehension quiz for the section spanning pages \(pageStart)–\(pageEnd) of \
        \"\(bookTitle)\" by \(bookAuthor). \
        Draw the four multiple-choice questions from events, characters, and ideas that appear in \
        that section. End with a short reflection prompt inviting the reader to record what \
        struck them.
        """
    }
}
