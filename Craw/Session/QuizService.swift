import Foundation

protocol QuizService: Sendable {
    func sections(bookName: String) async throws -> [String]
    func questions(bookName: String, sectionOrPage: String) async throws -> [APIQuizQuestion]
    func questionsForFinishedBook(bookName: String) async throws -> [APIQuizQuestion]
    func grade(bookName: String, sectionOrPage: String?, answers: [String]) async throws -> APIQuizGrade
}

struct LiveQuizService: QuizService {
    let client: CrawAPIClient

    func sections(bookName: String) async throws -> [String] {
        try await client.quizSections(bookName: bookName)
    }

    func questions(bookName: String, sectionOrPage: String) async throws -> [APIQuizQuestion] {
        try await client.quizQuestions(bookName: bookName, sectionOrPage: sectionOrPage)
    }

    func questionsForFinishedBook(bookName: String) async throws -> [APIQuizQuestion] {
        try await client.quizQuestionsForFinishedBook(bookName: bookName)
    }

    func grade(bookName: String, sectionOrPage: String?, answers: [String]) async throws -> APIQuizGrade {
        try await client.quizGrade(bookName: bookName, sectionOrPage: sectionOrPage, answers: answers)
    }
}

#if DEBUG
    struct MockQuizService: QuizService {
        func sections(bookName _: String) async throws -> [String] {
            try await Task.sleep(nanoseconds: 200_000_000)
            return [
                "Part I — Foundations",
                "Part II — The Habit Loop",
                "Part III — Identity & Systems",
                "Part IV — Advanced Tactics",
                "Conclusion & Appendix"
            ]
        }

        func questions(bookName _: String, sectionOrPage _: String) async throws -> [APIQuizQuestion] {
            try await Task.sleep(nanoseconds: 300_000_000)
            return Self.fixtureQuestions
        }

        func questionsForFinishedBook(bookName _: String) async throws -> [APIQuizQuestion] {
            try await Task.sleep(nanoseconds: 300_000_000)
            return Self.fixtureQuestions
        }

        func grade(bookName _: String, sectionOrPage _: String?, answers: [String]) async throws -> APIQuizGrade {
            try await Task.sleep(nanoseconds: 400_000_000)
            // Cycle 1 → 2 → 3 → 1 based on the first answer's hash so the dev can see all three feedback states.
            let seed = abs(answers.first?.hashValue ?? 0)
            let mark = (seed % 3) + 1
            return APIQuizGrade(mark: mark)
        }

        private static let fixtureQuestions: [APIQuizQuestion] = [
            APIQuizQuestion(
                question: "What is the central premise the author argues drives lasting behavior change?",
                options: [
                    "Willpower and motivation are the primary drivers",
                    "Small, consistent improvements compound over time",
                    "Radical, all-at-once transformations work best",
                    "External rewards are the most reliable motivator"
                ]
            ),
            APIQuizQuestion(
                question: "Which loop does the author use to describe how habits form?",
                options: [
                    "Trigger → Action → Reward → Repeat",
                    "Cue → Craving → Response → Reward",
                    "Stimulus → Response → Consequence",
                    "Intention → Plan → Execution → Review"
                ]
            ),
            APIQuizQuestion(
                question: "What does the author mean by an \"identity-based\" habit?",
                options: [
                    "A habit tied to a public commitment",
                    "A habit anchored in who you believe you are",
                    "A habit shared with a peer group",
                    "A habit driven by external accountability"
                ]
            ),
            APIQuizQuestion(
                question: "Which environmental change does the author most recommend for building new habits?",
                options: [
                    "Increase friction for unwanted behaviors",
                    "Wait for motivation to strike naturally",
                    "Rely on willpower in tempting situations",
                    "Avoid all reminders to stay relaxed"
                ]
            )
        ]
    }
#endif
