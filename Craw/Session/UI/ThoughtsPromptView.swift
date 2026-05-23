import SwiftUI

struct ThoughtsPromptView: View {
    let onContinue: ([String]) -> Void

    @State private var draft = ""
    @State private var thoughts: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    addRow
                    list
                }
                .padding(Theme.Spacing.lg)
            }
            footer
        }
        .background(Theme.Palette.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("What thoughts did you capture?")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
            Text("Add as many as you like. Skip if nothing landed today.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var addRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("A thought…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            Button(action: addThought) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(width: 36, height: 36)
                    .background(Theme.Palette.rausch, in: Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(Array(thoughts.enumerated()), id: \.offset) { idx, text in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Text(text)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        thoughts.remove(at: idx)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Palette.muted)
                            .frame(width: 28, height: 28)
                            .background(Theme.Palette.surfaceSoft, in: Circle())
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Palette.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
        }
    }

    private var footer: some View {
        Button(action: { onContinue(thoughts) }) {
            Text("Continue")
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.canvas)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Theme.Palette.rausch)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .padding(Theme.Spacing.lg)
    }

    private func addThought() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        thoughts.append(trimmed)
        draft = ""
    }
}
