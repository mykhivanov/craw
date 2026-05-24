import SwiftData
import SwiftUI

struct StudyBookTile: View {
    @Query(filter: BookLibraryReader.inProgressStudyPredicate, sort: BookLibraryReader.defaultSort)
    private var books: [Book]

    let onAddTapped: () -> Void

    var body: some View {
        AttitudeBookTile(
            label: "To study",
            book: books.first,
            emptyHeadline: "Pick something to study",
            emptyDescription: "Pick a book you’d like to learn from.",
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
        currentPage: 80,
        attitude: .study
    ))
    try? ctx.save()
    return NavigationStack { StudyBookTile(onAddTapped: {}) }
        .padding()
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { StudyBookTile(onAddTapped: {}) }
        .padding()
        .modelContainer(CrawModelContainer.previewInMemory())
}
