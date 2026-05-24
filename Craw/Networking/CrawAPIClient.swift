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
