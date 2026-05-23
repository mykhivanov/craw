import SwiftUI

struct QuizView: View {
    let quiz: GeneratedQuiz
    let onSubmit: (_ answers: [Int?], _ reflection: String) -> Void
    let onSkip: () -> Void

    @State private var currentIndex = 0
    @State private var answers: [Int?]
    @State private var reflection: String = ""
    @State private var stage: Stage = .questions

    private enum Stage { case questions, reflection }

    init(
        quiz: GeneratedQuiz,
        onSubmit: @escaping ([Int?], String) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.quiz = quiz
        self.onSubmit = onSubmit
        self.onSkip = onSkip
        _answers = State(initialValue: Array(repeating: nil, count: quiz.questions.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            content
        }
        .background(Theme.Palette.canvas)
    }

    private var topBar: some View {
        HStack {
            Text(stage == .questions
                ? "Question \(currentIndex + 1) of \(quiz.questions.count)"
                : "Reflection")
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
        switch stage {
        case .questions:
            questionContent
        case .reflection:
            reflectionContent
        }
    }

    private var questionContent: some View {
        let question = quiz.questions[currentIndex]
        return VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text(question.prompt)
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.lg)
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    optionButton(idx: idx, label: option, selected: answers[currentIndex] == idx)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            Spacer()
            primaryButton(
                label: currentIndex < quiz.questions.count - 1 ? "Next" : "To reflection",
                enabled: answers[currentIndex] != nil
            ) {
                if currentIndex < quiz.questions.count - 1 {
                    currentIndex += 1
                } else {
                    stage = .reflection
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var reflectionContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text(quiz.reflectionPrompt)
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.lg)
            TextEditor(text: $reflection)
                .font(Theme.Typography.bodyMd)
                .padding(Theme.Spacing.sm)
                .background(Theme.Palette.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .frame(minHeight: 160)
                .padding(.horizontal, Theme.Spacing.lg)
            Spacer()
            primaryButton(label: "Submit", enabled: true) {
                onSubmit(answers, reflection.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func optionButton(idx: Int, label: String, selected: Bool) -> some View {
        Button {
            answers[currentIndex] = idx
        } label: {
            HStack {
                Text(label)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Palette.rausch)
                }
            }
            .padding(Theme.Spacing.base)
            .background(selected ? Theme.Palette.rausch.opacity(0.08) : Theme.Palette.surfaceSoft)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(selected ? Theme.Palette.rausch : Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }

    private func primaryButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.canvas)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(enabled ? Theme.Palette.rausch : Theme.Palette.rausch.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(!enabled)
    }
}

struct QuizUnavailableView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.Palette.mutedSoft)
            VStack(spacing: Theme.Spacing.xs) {
                Text("Skip verification this time")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("We couldn't build a quiz for this section. Your streak still counts.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            Button(action: onContinue) {
                Text("OK, continue")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.canvas)
    }
}
