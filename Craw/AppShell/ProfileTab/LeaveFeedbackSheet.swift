import SwiftUI

struct LeaveFeedbackSheet: View {
    let apiClient: CrawAPIClient
    let onSubmitted: (APIUser) -> Void
    let onAlreadySubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private let maxLength = 2000

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .frame(minHeight: 160)
                        .font(Theme.Typography.bodyMd)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxLength {
                                text = String(newValue.prefix(maxLength))
                            }
                        }
                } header: {
                    Text("Your feedback")
                } footer: {
                    HStack {
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(Theme.Palette.trendDown)
                        }
                        Spacer()
                        Text("\(text.count)/\(maxLength)")
                            .foregroundStyle(Theme.Palette.mutedSoft)
                    }
                    .font(Theme.Typography.captionSm)
                }
            }
            .navigationTitle("Leave feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSending ? "Sending…" : "Send") {
                        Task { await send() }
                    }
                    .disabled(isSendDisabled)
                }
            }
        }
    }

    private var isSendDisabled: Bool {
        isSending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let updated = try await apiClient.submitFeedback(.init(feedback: trimmed))
            onSubmitted(updated)
            dismiss()
        } catch APIError.feedbackAlreadySubmitted {
            onAlreadySubmitted()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.userFacingMessage ?? "Couldn't send. Please try again."
        }
    }
}
