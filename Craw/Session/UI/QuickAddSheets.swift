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
                Section("Page") {
                    TextField("Page number", text: $pageText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add quote")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if pageText.isEmpty {
                    pageText = String(engine.currentPage)
                }
            }
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
        modelContext.insert(Quote(
            bookID: bookID,
            text: trimmed,
            pageNumber: Int(pageText)
        ))
        try? modelContext.save()
        dismiss()
    }
}

struct QuickAddThoughtSheet: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Thought") {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                        .font(Theme.Typography.bodyMd)
                }
            }
            .navigationTitle("Add thought")
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
        modelContext.insert(Thought(bookID: bookID, text: trimmed))
        try? modelContext.save()
        dismiss()
    }
}
