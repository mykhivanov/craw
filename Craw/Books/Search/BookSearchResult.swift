import Foundation

struct BookSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let totalPages: Int
    let coverImageURL: URL?
    let isbn: String?

    init(
        id: String,
        title: String,
        author: String,
        totalPages: Int,
        coverImageURL: URL? = nil,
        isbn: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.coverImageURL = coverImageURL
        self.isbn = isbn
    }

    init(dto: SearchBookDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            author: dto.author,
            totalPages: dto.totalPages,
            coverImageURL: dto.coverImageURL,
            isbn: dto.isbn
        )
    }
}
