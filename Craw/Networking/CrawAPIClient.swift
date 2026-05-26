import Foundation
import os

actor CrawAPIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: AuthTokenProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger = Logger(subsystem: "com.mykhivanov.Craw", category: "CrawAPIClient")

    init(baseURL: URL, session: URLSession = .shared, tokenProvider: AuthTokenProvider) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        decoder = JSONDecoder.crawDefault
        encoder = JSONEncoder.crawDefault
    }

    func bootstrapSession() async throws -> APIUser {
        try await performGet(path: "/auth/session", method: "POST", query: [])
    }

    func searchBooks(query: String, limit: Int = 20, offset: Int = 0) async throws -> BookSearchPage {
        try await performGet(
            path: "/books/search",
            method: "GET",
            query: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        )
    }

    func registerDevice(
        token: String,
        platform: String,
        appVersion: String,
        locale: String
    ) async throws -> APIDevice {
        let body = APIDeviceRegistration(
            token: token,
            platform: platform,
            appVersion: appVersion,
            locale: locale
        )
        let bodyData = try encoder.encode(body)
        return try await performWithBody(
            path: "/devices",
            method: "POST",
            bodyData: bodyData
        )
    }

    func submitFeedback(_ submission: APIFeedbackSubmission) async throws -> APIUser {
        let bodyData = try encoder.encode(submission)
        return try await performWithBody(
            path: "/users/me/feedback",
            method: "POST",
            bodyData: bodyData
        )
    }

    func deleteAccount() async throws {
        try await sendNoContent(path: "/users/me", method: "DELETE")
    }

    // MARK: - Quiz

    func quizSections(bookName: String) async throws -> [String] {
        let body = APIQuizSectionsRequest(bookName: bookName)
        let bodyData = try encoder.encode(body)
        return try await performWithBody(
            path: "/quiz/sections",
            method: "POST",
            bodyData: bodyData
        )
    }

    func quizQuestions(bookName: String, sectionOrPage: String) async throws -> [APIQuizQuestion] {
        let body = APIQuizQuestionsRequestWithSection(
            bookName: bookName,
            sectionOrPage: sectionOrPage
        )
        let bodyData = try encoder.encode(body)
        return try await performWithBody(
            path: "/quiz/questions",
            method: "POST",
            bodyData: bodyData
        )
    }

    func quizQuestionsForFinishedBook(bookName: String) async throws -> [APIQuizQuestion] {
        let body = APIQuizQuestionsRequestFinished(bookName: bookName, finished: true)
        let bodyData = try encoder.encode(body)
        return try await performWithBody(
            path: "/quiz/questions",
            method: "POST",
            bodyData: bodyData
        )
    }

    func quizGrade(
        bookName: String,
        sectionOrPage: String?,
        answers: [String]
    ) async throws -> APIQuizGrade {
        let body = APIQuizGradeRequest(
            bookName: bookName,
            sectionOrPage: sectionOrPage,
            answers: answers
        )
        let bodyData = try encoder.encode(body)
        let grade: APIQuizGrade = try await performWithBody(
            path: "/quiz/grade",
            method: "POST",
            bodyData: bodyData
        )
        guard (1...3).contains(grade.mark) else {
            throw APIError.decoding(QuizGradeOutOfRange(mark: grade.mark))
        }
        return grade
    }

    private func sendNoContent(path: String, method: String) async throws {
        do {
            try await sendDiscardingResponse(
                path: path,
                method: method,
                bodyData: nil,
                forceRefreshToken: false
            )
        } catch APIError.unauthorized {
            try await sendDiscardingResponse(
                path: path,
                method: method,
                bodyData: nil,
                forceRefreshToken: true
            )
        }
    }

    private func sendDiscardingResponse(
        path: String,
        method: String,
        bodyData: Data?,
        forceRefreshToken: Bool
    ) async throws {
        try Task.checkCancellation()
        let token = try await tokenProvider.currentToken(forceRefresh: forceRefreshToken)
        let request = try buildRequest(
            path: path,
            method: method,
            query: [],
            bodyData: bodyData,
            token: token
        )
        let response: URLResponse
        let data: Data
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw APIError.cancelled
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(message: "Invalid response", code: nil)
        }
        try mapStatus(data: data, response: http)
    }

    private func mapStatus(data: Data, response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.feedbackAlreadySubmitted
        case 429:
            let retry = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retry)
        default:
            if let body = try? decoder.decode(APIErrorBody.self, from: data) {
                throw APIError.server(message: body.message, code: body.code)
            }
            throw APIError.server(message: "HTTP \(response.statusCode)", code: nil)
        }
    }

    private func performGet<Response: Decodable>(
        path: String,
        method: String,
        query: [URLQueryItem]
    ) async throws -> Response {
        do {
            return try await sendOnce(
                path: path,
                method: method,
                query: query,
                bodyData: nil,
                forceRefreshToken: false
            )
        } catch APIError.unauthorized {
            return try await sendOnce(
                path: path,
                method: method,
                query: query,
                bodyData: nil,
                forceRefreshToken: true
            )
        }
    }

    private func performWithBody<Response: Decodable>(
        path: String,
        method: String,
        bodyData: Data
    ) async throws -> Response {
        do {
            return try await sendOnce(
                path: path,
                method: method,
                query: [],
                bodyData: bodyData,
                forceRefreshToken: false
            )
        } catch APIError.unauthorized {
            return try await sendOnce(
                path: path,
                method: method,
                query: [],
                bodyData: bodyData,
                forceRefreshToken: true
            )
        }
    }

    private func sendOnce<Response: Decodable>(
        path: String,
        method: String,
        query: [URLQueryItem],
        bodyData: Data?,
        forceRefreshToken: Bool
    ) async throws -> Response {
        try Task.checkCancellation()
        let token = try await tokenProvider.currentToken(forceRefresh: forceRefreshToken)
        let request = try buildRequest(
            path: path,
            method: method,
            query: query,
            bodyData: bodyData,
            token: token
        )
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw APIError.cancelled
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(message: "Invalid response", code: nil)
        }
        return try map(data: data, response: http)
    }

    private func buildRequest(
        path: String,
        method: String,
        query: [URLQueryItem],
        bodyData: Data?,
        token: String
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path.trimmingPrefixSlash)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let composed = components?.url else {
            throw APIError.server(message: "Could not build URL for \(path)", code: nil)
        }
        var request = URLRequest(url: composed)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bodyData {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
        }
        if let client = bundleClientHeader() {
            request.setValue(client, forHTTPHeaderField: "X-Craw-Client")
        }
        return request
    }

    private func map<Response: Decodable>(data: Data, response: HTTPURLResponse) throws -> Response {
        switch response.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                logger.error("Decoding failed: \(error.localizedDescription, privacy: .public)")
                throw APIError.decoding(error)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.feedbackAlreadySubmitted
        case 429:
            let retry = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retry)
        default:
            if let body = try? decoder.decode(APIErrorBody.self, from: data) {
                throw APIError.server(message: body.message, code: body.code)
            }
            let bodyText = String(data: data, encoding: .utf8) ?? "<empty>"
            logger.error("HTTP \(response.statusCode, privacy: .public): \(bodyText, privacy: .public)")
            throw APIError.server(message: "HTTP \(response.statusCode)", code: nil)
        }
    }

    private func bundleClientHeader() -> String? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        guard let version, let build else { return nil }
        return "ios/\(version)+\(build)"
    }
}

extension JSONDecoder {
    static var crawDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }
}

extension JSONEncoder {
    static var crawDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFractionalSeconds
        return encoder
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = ISO8601DateFormatter.crawFractional.date(from: raw)
                ?? ISO8601DateFormatter.crawPlain.date(from: raw)
            {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 date: \(raw)")
        }
    }
}

private extension JSONEncoder.DateEncodingStrategy {
    static var iso8601WithFractionalSeconds: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.crawFractional.string(from: date))
        }
    }
}

private extension ISO8601DateFormatter {
    static let crawFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let crawPlain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private extension String {
    var trimmingPrefixSlash: String {
        hasPrefix("/") ? String(dropFirst()) : self
    }
}

/// Sentinel error for a `POST /quiz/grade` response whose `mark` falls outside `1...3`.
/// Wrapped as `APIError.decoding(_)` so the existing error envelope is preserved.
private struct QuizGradeOutOfRange: Error {
    let mark: Int
}
