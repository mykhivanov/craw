import Foundation
import Observation
import os

@Observable
@MainActor
final class DeviceRegistrationCoordinator {
    private let apiClient: CrawAPIClient
    private let logger = Logger(subsystem: "com.mykhivanov.Craw", category: "DeviceRegistration")

    private var latestToken: String?
    private var lastSentToken: String?
    private var sessionReady: Bool = false
    private var inFlight: Bool = false

    private(set) var lastRegistrationError: String?

    init(apiClient: CrawAPIClient) {
        self.apiClient = apiClient
    }

    func tokenAvailable(_ token: String) {
        guard !token.isEmpty else { return }
        latestToken = token
        Task { await flushIfPossible() }
    }

    func sessionDidBecomeReady() {
        sessionReady = true
        Task { await flushIfPossible() }
    }

    func sessionDidReset() {
        sessionReady = false
        lastSentToken = nil
    }

    private func flushIfPossible() async {
        guard sessionReady, !inFlight, let token = latestToken, token != lastSentToken else { return }
        inFlight = true
        defer { inFlight = false }

        let info = Bundle.main.infoDictionary
        let appVersion = (info?["CFBundleShortVersionString"] as? String) ?? "unknown"
        let locale = Locale.current.identifier(.bcp47)
        do {
            _ = try await apiClient.registerDevice(
                token: token,
                platform: "ios",
                appVersion: appVersion,
                locale: locale
            )
            lastSentToken = token
            lastRegistrationError = nil
        } catch APIError.notFound {
            logger.warning("POST /devices returned 404 — backend endpoint not deployed yet; will retry on next signal.")
        } catch {
            let message = (error as? APIError)?.userFacingMessage ?? error.localizedDescription
            lastRegistrationError = message
            logger.error("POST /devices failed: \(message, privacy: .public)")
        }
    }
}
