import FoundationModels

@Generable
struct GeneratedQuiz: Equatable {
    @Guide(
        description: "Exactly four multiple-choice questions about the book section the user just read.",
        .count(Theme.Quiz.questionCount)
    )
    let questions: [GeneratedQuestion]

    @Guide(description: "A single open-ended reflection prompt the user can answer in their own words.")
    let reflectionPrompt: String
}

@Generable
struct GeneratedQuestion: Equatable {
    @Guide(description: "The question text — concrete and answerable from the section.")
    let prompt: String

    @Guide(description: "Exactly four mutually distinct answer options.", .count(4))
    let options: [String]

    @Guide(
        description: "Zero-based index of the correct option in the options array.",
        .range(0...3)
    )
    let correctIndex: Int
}
