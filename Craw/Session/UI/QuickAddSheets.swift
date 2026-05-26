import SwiftData
import SwiftUI

struct QuickAddQuoteSheet: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var pageText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .font(Theme.Typography.bodyMd)
                }
                Section("Page (optional)") {
                    TextField("Page number", text: $pageText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let bookID = engine.book?.id else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let trimmedPage = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pageNumber = trimmedPage.isEmpty ? nil : Int(trimmedPage)
        modelContext.insert(Quote(
            bookID: bookID,
            text: trimmed,
            pageNumber: pageNumber
        ))
        try? modelContext.save()
        dismiss()
    }
}
