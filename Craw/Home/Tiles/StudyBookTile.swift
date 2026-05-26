import SwiftData
import SwiftUI

struct StudyBookTile: View {
    @Query(filter: BookLibraryReader.inProgressStudyPredicate, sort: BookLibraryReader.defaultSort)
    private var books: [Book]

    let onStart: (Book) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "To study",
            book: books.first,
            emptyHeadline: "Add a book to study",
            emptyDescription: "Pick something you'd like to learn from.",
            onStart: onStart,
            onAddTapped: onAddTapped
        )
    }
}

#Preview("With book") {
    let container = CrawModelContainer.previewInMemory()
    let ctx = ModelContext(container)
    ctx.insert(Book(
        title: "The Pragmatic Programmer",
        author: "Hunt & Thomas",
        totalPages: 320,
        attitude: .study
    ))
    try? ctx.save()
    return StudyBookTile(onStart: { _ in }, onAddTapped: {})
        .padding()
        .modelContainer(container)
}

#Preview("Empty") {
    StudyBookTile(onStart: { _ in }, onAddTapped: {})
        .padding()
        .modelContainer(CrawModelContainer.previewInMemory())
}
