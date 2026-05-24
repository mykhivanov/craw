import SwiftData
import SwiftUI

struct EntertainmentBookTile: View {
    @Query(filter: BookLibraryReader.inProgressEntertainmentPredicate, sort: BookLibraryReader.defaultSort)
    private var books: [Book]

    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "For fun",
            book: books.first,
            emptyHeadline: "Pick something for fun",
            emptyDescription: "Add a book just for enjoyment.",
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
        currentPage: 60,
        attitude: .entertainment
    ))
    try? ctx.save()
    return NavigationStack { EntertainmentBookTile(onAddTapped: {}) }
        .padding()
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { EntertainmentBookTile(onAddTapped: {}) }
        .padding()
        .modelContainer(CrawModelContainer.previewInMemory())
}
