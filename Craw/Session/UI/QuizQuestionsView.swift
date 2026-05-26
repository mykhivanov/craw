import SwiftUI

struct QuizQuestionsView: View {
    let bookName: String
    /// `nil` means the user reached the quiz via "Book is finished" — fetch via the
    /// finished-book endpoint variant and submit `sectionOrPage: nil` on grading.
    let sectionOrPage: String?
    let onGrade: (Int) -> Void
    let onSkip: () -> Void
    let onError: () -> Void

    @State private var questions: [APIQuizQuestion] = []
    @State private var loadState: LoadState = .loading
    @State private var selectedOptions: [Int: String] = [:]
    @State private var isSubmitting = false

    private enum LoadState: Equatable {
        case loading
        case loaded
        case failed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            content
        }
        .background(Theme.Palette.canvas)
        .task {
            await loadQuestions()
        }
    }

    private var topBar: some View {
        HStack {
            Text("Quiz")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            Spacer()
            Button("Skip", action: onSkip)
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(Theme.Palette.muted)
        }
        .padding(Theme.Spacing.base)
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            ProgressView()
                .tint(Theme.Palette.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            loadedContent
        case .failed:
            EmptyView()
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { idx, question in
                        questionBlock(idx: idx, question: question)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            submitButton
                .padding(Theme.Spacing.lg)
        }
    }

    private func questionBlock(idx: Int, question: APIQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(question.prompt(prefix: "\(idx + 1). "))
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { _, option in
                    let isSelected = selectedOptions[idx] == option
                    Button {
                        selectedOptions[idx] = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(Theme.Typography.bodyMd)
                                .foregroundStyle(Theme.Palette.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.Palette.rausch)
                            }
                        }
                        .padding(Theme.Spacing.base)
                        .background(isSelected ? Theme.Palette.rausch.opacity(0.08) : Theme.Palette.surfaceSoft)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                .stroke(isSelected ? Theme.Palette.rausch : Theme.Palette.hairlineSoft, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView().tint(Theme.Palette.canvas)
                }
                Text(isSubmitting ? "Grading…" : "Continue")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(canSubmit ? Theme.Palette.rausch : Theme.Palette.rauschDisabled)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(!canSubmit || isSubmitting)
    }

    private var canSubmit: Bool {
        !questions.isEmpty && questions.indices.allSatisfy { selectedOptions[$0] != nil }
    }

    private func loadQuestions() async {
        do {
            let result: [APIQuizQuestion] = if let sectionOrPage {
                try await AppEnvironment.liveAPIClient.quizQuestions(
                    bookName: bookName,
                    sectionOrPage: sectionOrPage
                )
            } else {
                try await AppEnvironment.liveAPIClient.quizQuestionsForFinishedBook(
                    bookName: bookName
                )
            }
            questions = result
            loadState = .loaded
        } catch {
            loadState = .failed
            onError()
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        let answers = questions.indices.compactMap { selectedOptions[$0] }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let grade = try await AppEnvironment.liveAPIClient.quizGrade(
                bookName: bookName,
                sectionOrPage: sectionOrPage,
                answers: answers
            )
            onGrade(grade.mark)
        } catch {
            onSkip()
        }
    }
}

private extension APIQuizQuestion {
    func prompt(prefix: String) -> String {
        prefix + question
    }
}
