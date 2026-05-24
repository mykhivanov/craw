import Foundation

struct BookSearchPage: Decodable {
    let items: [SearchBookDTO]
    let nextOffset: Int?

    enum CodingKeys: String, CodingKey {
        case items
        case nextOffset = "next_offset"
    }
}

struct SearchBookDTO: Decodable {
    let id: String
    let title: String
    let author: String
    let totalPages: Int
    let coverImageURL: URL?
    let isbn: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case totalPages = "total_pages"
        case coverImageURL = "cover_image_url"
        case isbn
    }
}
