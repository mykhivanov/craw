import SwiftUI

struct EntertainmentBookTile: View {
    let book: Book?
    let onStart: (Book) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "For fun",
            book: book,
            emptyHeadline: "Add a book for fun",
            emptyDescription: "Pick something just for enjoyment.",
            onStart: onStart,
            onAddTapped: onAddTapped
        )
    }
}

#Preview("With book") {
    EntertainmentBookTile(book: Book(
        title: "Project Hail Mary",
        author: "Andy Weir",
        coverAssetName: "book_cover_sample_a",
        totalPages: 480,
        attitude: .entertainment
    ), onStart: { _ in }, onAddTapped: {})
        .padding()
}

#Preview("Empty") {
    EntertainmentBookTile(book: nil, onStart: { _ in }, onAddTapped: {})
        .padding()
}
