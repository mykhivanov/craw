import SwiftData
import SwiftUI

struct EntertainmentBookTile: View {
    @Query(filter: BookLibraryReader.inProgressEntertainmentPredicate, sort: BookLibraryReader.defaultSort)
    private var books: [Book]

    let onStart: (Book) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "For fun",
            book: books.first,
            emptyHeadline: "Add a book for fun",
            emptyDescription: "Pick something just for enjoyment.",
            onStart: onStart,
            onAddTapped: onAddTapped
        )
    }
}

#Preview("With book") {
    let container = CrawModelContainer.previewInMemory()
    let ctx = ModelContext(container)
    ctx.insert(Book(
        title: "Project Hail Mary",
        author: "Andy Weir",
        coverAssetName: "book_cover_sample_a",
        totalPages: 480,
        attitude: .entertainment
    ))
    try? ctx.save()
    return EntertainmentBookTile(onStart: { _ in }, onAddTapped: {})
        .padding()
        .modelContainer(container)
}

#Preview("Empty") {
    EntertainmentBookTile(onStart: { _ in }, onAddTapped: {})
        .padding()
        .modelContainer(CrawModelContainer.previewInMemory())
}
