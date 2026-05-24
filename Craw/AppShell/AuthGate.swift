import ClerkKit
import ClerkKitUI
import SwiftUI

struct AuthGate: View {
    @Environment(Clerk.self) private var clerk
    @Environment(NotificationsService.self) private var notifications
    @Environment(DeviceRegistrationCoordinator.self) private var deviceRegistration
    @Environment(\.scenePhase) private var scenePhase

    @State private var sessionStore: AuthSessionStore = AppEnvironment.makeAuthSessionStore()
    @State private var onboardingState: OnboardingState = .init()

    var body: some View {
        contentForState
            .onChange(of: clerk.user?.id) { _, newID in
                if newID == nil {
                    sessionStore.reset()
                    deviceRegistration.sessionDidReset()
                    Task { await notifications.clearScheduledReminders() }
                } else {
                    sessionStore.bootstrapIfNeeded()
                }
            }
            .onChange(of: sessionStore.status) { _, newStatus in
                if case .ready = newStatus {
                    deviceRegistration.sessionDidBecomeReady()
                }
            }
            .onChange(of: notifications.fcmToken) { _, newToken in
                if let newToken, !newToken.isEmpty {
                    deviceRegistration.tokenAvailable(newToken)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, clerk.user != nil {
                    sessionStore.retryIfTransient()
                }
            }
            .task {
                await notifications.refreshAuthorizationStatus()
                if clerk.user != nil {
                    sessionStore.bootstrapIfNeeded()
                }
            }
    }

    @ViewBuilder
    private var contentForState: some View {
        if !clerk.isLoaded {
            SplashView()
        } else if clerk.user == nil {
            if onboardingState.isCompleted || OnboardingState.shouldSkipFromLaunchArgs {
                CrawAuthView()
            } else {
                OnboardingView()
                    .environment(onboardingState)
            }
        } else {
            RootView()
                .environment(sessionStore)
        }
    }
}
