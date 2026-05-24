import Foundation

enum APIError: Error {
    case unauthorized
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case server(message: String, code: String?)
    case network(URLError)
    case decoding(Error)
    case cancelled
    case feedbackAlreadySubmitted
}

extension APIError {
    var userFacingMessage: String {
        switch self {
        case .unauthorized:
            "Your session has expired. Please sign in again."
        case .notFound:
            "Couldn't find what you were looking for."
        case .rateLimited:
            "Too many requests. Please try again in a moment."
        case let .server(message, _):
            message
        case .network:
            "Network is unavailable. Check your connection and try again."
        case .decoding:
            "Received an unexpected response. Please try again."
        case .cancelled:
            ""
        case .feedbackAlreadySubmitted:
            "Feedback already submitted."
        }
    }
}

struct APIErrorBody: Decodable {
    let code: String
    let message: String
}
