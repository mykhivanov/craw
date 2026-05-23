import Foundation
import Testing
@testable import Craw

@Suite("QuizValidator")
struct QuizValidatorTests {
    private func validQuestion(correct: Int = 0) -> GeneratedQuestion {
        GeneratedQuestion(
            prompt: "Who finds the ring?",
            options: ["Bilbo", "Sam", "Frodo", "Gandalf"],
            correctIndex: correct
        )
    }

    private func validQuiz() -> GeneratedQuiz {
        GeneratedQuiz(
            questions: [
                validQuestion(),
                validQuestion(correct: 1),
                validQuestion(correct: 2),
                validQuestion(correct: 3)
            ],
            reflectionPrompt: "What surprised you?"
        )
    }

    @Test("Valid quiz passes")
    func validQuizPasses() {
        let result = QuizValidator.validate(validQuiz())
        guard case .success = result else {
            Issue.record("Expected success, got \(result)")
            return
        }
    }

    @Test("Three questions instead of four is rejected")
    func wrongQuestionCount() {
        let quiz = GeneratedQuiz(
            questions: Array(repeating: validQuestion(), count: 3),
            reflectionPrompt: "Why?"
        )
        let result = QuizValidator.validate(quiz)
        guard case let .failure(.wrongQuestionCount(n)) = result else {
            Issue.record("Expected wrongQuestionCount")
            return
        }
        #expect(n == 3)
    }

    @Test("Duplicate options are rejected (case-insensitive)")
    func duplicateOptions() {
        let bad = GeneratedQuestion(
            prompt: "Q?",
            options: ["Yes", "yes", "No", "Maybe"],
            correctIndex: 0
        )
        let quiz = GeneratedQuiz(
            questions: [bad, validQuestion(correct: 1), validQuestion(correct: 2), validQuestion(correct: 3)],
            reflectionPrompt: "Why?"
        )
        let result = QuizValidator.validate(quiz)
        guard case let .failure(.duplicateOptions(idx)) = result else {
            Issue.record("Expected duplicateOptions")
            return
        }
        #expect(idx == 0)
    }

    @Test("Out-of-range correctIndex is rejected")
    func correctIndexOutOfRange() {
        let bad = GeneratedQuestion(prompt: "Q?", options: ["A", "B", "C", "D"], correctIndex: 5)
        let quiz = GeneratedQuiz(
            questions: [bad, validQuestion(), validQuestion(correct: 2), validQuestion(correct: 3)],
            reflectionPrompt: "Why?"
        )
        let result = QuizValidator.validate(quiz)
        guard case let .failure(.correctIndexOutOfRange(idx, value)) = result else {
            Issue.record("Expected correctIndexOutOfRange")
            return
        }
        #expect(idx == 0)
        #expect(value == 5)
    }

    @Test("Wrong option count is rejected")
    func wrongOptionCount() {
        let bad = GeneratedQuestion(prompt: "Q?", options: ["A", "B", "C"], correctIndex: 0)
        let quiz = GeneratedQuiz(
            questions: [bad, validQuestion(), validQuestion(correct: 2), validQuestion(correct: 3)],
            reflectionPrompt: "Why?"
        )
        let result = QuizValidator.validate(quiz)
        guard case let .failure(.wrongOptionCount(idx, count)) = result else {
            Issue.record("Expected wrongOptionCount")
            return
        }
        #expect(idx == 0)
        #expect(count == 3)
    }

    @Test("Empty reflection is rejected")
    func emptyReflection() {
        let quiz = GeneratedQuiz(
            questions: [
                validQuestion(),
                validQuestion(correct: 1),
                validQuestion(correct: 2),
                validQuestion(correct: 3)
            ],
            reflectionPrompt: "   "
        )
        let result = QuizValidator.validate(quiz)
        guard case .failure(.emptyReflection) = result else {
            Issue.record("Expected emptyReflection")
            return
        }
    }
}

@MainActor
@Suite("QuizService grader")
struct QuizGraderTests {
    private func makeQuiz() -> GeneratedQuiz {
        GeneratedQuiz(
            questions: [
                GeneratedQuestion(prompt: "Q1", options: ["A", "B", "C", "D"], correctIndex: 0),
                GeneratedQuestion(prompt: "Q2", options: ["A", "B", "C", "D"], correctIndex: 1),
                GeneratedQuestion(prompt: "Q3", options: ["A", "B", "C", "D"], correctIndex: 2),
                GeneratedQuestion(prompt: "Q4", options: ["A", "B", "C", "D"], correctIndex: 3)
            ],
            reflectionPrompt: "Why?"
        )
    }

    @Test("Three correct out of four is verified")
    func atThreshold() {
        let service = QuizService()
        let outcome = service.grade(answers: [0, 1, 2, 0], against: makeQuiz())
        guard case let .verified(count) = outcome else {
            Issue.record("Expected verified")
            return
        }
        #expect(count == 3)
    }

    @Test("Two correct out of four is failed")
    func belowThreshold() {
        let service = QuizService()
        let outcome = service.grade(answers: [0, 1, 0, 0], against: makeQuiz())
        guard case let .failed(count) = outcome else {
            Issue.record("Expected failed")
            return
        }
        #expect(count == 2)
    }

    @Test("Unanswered questions count as wrong")
    func unansweredCountsWrong() {
        let service = QuizService()
        let outcome = service.grade(answers: [0, nil, 2, 3], against: makeQuiz())
        guard case let .verified(count) = outcome else {
            Issue.record("Expected verified")
            return
        }
        #expect(count == 3)
    }
}
