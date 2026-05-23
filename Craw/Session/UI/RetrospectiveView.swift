import SwiftUI

struct RetrospectiveView: View {
    let onSubmit: (_ start: Int, _ focus: Int, _ enjoyment: Int) -> Void

    @State private var startDifficulty: Int?
    @State private var focusDifficulty: Int?
    @State private var enjoyment: Int?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("How was the session?")
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                    ratingRow(label: "How hard was it to start today?", selection: $startDifficulty)
                    ratingRow(label: "How hard was it to focus?", selection: $focusDifficulty)
                    ratingRow(label: "How much did you enjoy it?", selection: $enjoyment)
                }
                .padding(Theme.Spacing.lg)
            }
            Button(action: submit) {
                Text("Continue")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canSubmit ? Theme.Palette.rausch : Theme.Palette.rausch.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .disabled(!canSubmit)
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Palette.canvas)
    }

    private var canSubmit: Bool {
        startDifficulty != nil && focusDifficulty != nil && enjoyment != nil
    }

    private func ratingRow(label: String, selection: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.titleSm)
                .foregroundStyle(Theme.Palette.ink)
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        selection.wrappedValue = value
                    } label: {
                        Text("\(value)")
                            .font(Theme.Typography.buttonMd)
                            .foregroundStyle(selection.wrappedValue == value
                                ? Theme.Palette.canvas
                                : Theme.Palette.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(selection.wrappedValue == value
                                ? Theme.Palette.rausch
                                : Theme.Palette.surfaceSoft)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                }
            }
        }
    }

    private func submit() {
        guard let s = startDifficulty, let f = focusDifficulty, let e = enjoyment else { return }
        onSubmit(s, f, e)
    }
}
