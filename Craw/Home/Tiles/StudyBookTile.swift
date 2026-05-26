import SwiftUI

struct StudyBookTile: View {
    let book: Book?
    let onStart: (Book) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "To study",
            book: book,
            emptyHeadline: "Add a book to study",
            emptyDescription: "Pick something you'd like to learn from.",
            onStart: onStart,
            onAddTapped: onAddTapped
        )
    }
}

#Preview("With book") {
    StudyBookTile(book: Book(
        title: "The Pragmatic Programmer",
        author: "Hunt & Thomas",
        totalPages: 320,
        attitude: .study
    ), onStart: { _ in }, onAddTapped: {})
        .padding()
}

#Preview("Empty") {
    StudyBookTile(book: nil, onStart: { _ in }, onAddTapped: {})
        .padding()
}
