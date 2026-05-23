import Foundation

enum QuizValidationFailure: Error, Equatable {
    case wrongQuestionCount(Int)
    case wrongOptionCount(questionIndex: Int, count: Int)
    case duplicateOptions(questionIndex: Int)
    case correctIndexOutOfRange(questionIndex: Int, index: Int)
    case emptyReflection
}

enum QuizValidator {
    static func validate(_ quiz: GeneratedQuiz) -> Result<GeneratedQuiz, QuizValidationFailure> {
        if quiz.questions.count != Theme.Quiz.questionCount {
            return .failure(.wrongQuestionCount(quiz.questions.count))
        }
        for (idx, question) in quiz.questions.enumerated() {
            if question.options.count != 4 {
                return .failure(.wrongOptionCount(questionIndex: idx, count: question.options.count))
            }
            let normalized = question.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            if Set(normalized).count != question.options.count {
                return .failure(.duplicateOptions(questionIndex: idx))
            }
            if !(0..<4).contains(question.correctIndex) {
                return .failure(.correctIndexOutOfRange(questionIndex: idx, index: question.correctIndex))
            }
        }
        if quiz.reflectionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure(.emptyReflection)
        }
        return .success(quiz)
    }
}
