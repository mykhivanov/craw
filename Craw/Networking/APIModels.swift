import Foundation

struct APIUser: Decodable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let createdAt: Date
    let library: APILibrary
    let feedback: String?
    let feedbackSubmittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case createdAt
        case library
        case feedback
        case feedbackSubmittedAt = "feedback_submitted_at"
    }
}

struct APIFeedbackSubmission: Encodable {
    let feedback: String
}

struct APILibrary: Decodable, Equatable {
    let inProgress: [APILibraryBook]
    let finished: [APILibraryBook]
}

struct APILibraryBook: Decodable, Equatable {
    let id: String
    let bookID: String?
    let title: String
    let author: String
    let totalPages: Int
    let currentPage: Int
    let status: Status
    let progressPercent: Double
    let coverImageURL: URL?
    let isbn: String?
    let description: String?
    let publishedYear: Int?
    let language: String?
    let dateAdded: Date
    let dateStarted: Date?
    let dateFinished: Date?
    let lastReadAt: Date?

    enum Status: String, Decodable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case finished
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bookID = "book_id"
        case title
        case author
        case totalPages = "total_pages"
        case currentPage = "current_page"
        case status
        case progressPercent = "progress_percent"
        case coverImageURL = "cover_image_url"
        case isbn
        case description
        case publishedYear = "published_year"
        case language
        case dateAdded = "date_added"
        case dateStarted = "date_started"
        case dateFinished = "date_finished"
        case lastReadAt = "last_read_at"
    }
}

struct APIDevice: Decodable, Equatable {
    let id: String
    let userID: String
    let token: String
    let platform: String
    let appVersion: String
    let locale: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case token
        case platform
        case appVersion = "app_version"
        case locale
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APIDeviceRegistration: Encodable {
    let token: String
    let platform: String
    let appVersion: String
    let locale: String

    enum CodingKeys: String, CodingKey {
        case token
        case platform
        case appVersion = "app_version"
        case locale
    }
}

// MARK: - Quiz

struct APIQuizSectionsRequest: Encodable {
    let bookName: String

    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
    }
}

struct APIQuizQuestionsRequestWithSection: Encodable {
    let bookName: String
    let sectionOrPage: String

    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
        case sectionOrPage = "section_or_page"
    }
}

struct APIQuizQuestionsRequestFinished: Encodable {
    let bookName: String
    let finished: Bool

    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
        case finished
    }
}

struct APIQuizQuestion: Decodable, Equatable {
    let question: String
    let options: [String]
}

/// `section_or_page` is omitted from the wire when nil so the server can distinguish
/// the book-finished path (no selection) from a normal section/page submission.
struct APIQuizGradeRequest: Encodable {
    let bookName: String
    let sectionOrPage: String?
    let answers: [String]

    enum CodingKeys: String, CodingKey {
        case bookName = "book_name"
        case sectionOrPage = "section_or_page"
        case answers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bookName, forKey: .bookName)
        if let sectionOrPage {
            try container.encode(sectionOrPage, forKey: .sectionOrPage)
        }
        try container.encode(answers, forKey: .answers)
    }
}

struct APIQuizGrade: Decodable, Equatable {
    let mark: Int
}
