import ClerkKit
import ClerkKitUI
import SwiftUI

struct AuthGate: View {
    @Environment(Clerk.self) private var clerk
    @Environment(\.scenePhase) private var scenePhase

    @State private var sessionStore: AuthSessionStore = AppEnvironment.makeAuthSessionStore()
    @State private var onboardingState: OnboardingState = .init()

    var body: some View {
        contentForState
            .onChange(of: clerk.user?.id) { _, newID in
                if newID == nil {
                    sessionStore.reset()
                } else {
                    sessionStore.bootstrapIfNeeded()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, clerk.user != nil {
                    sessionStore.retryIfTransient()
                }
            }
            .task {
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
                AuthView(mode: .signInOrUp, isDismissable: false)
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
