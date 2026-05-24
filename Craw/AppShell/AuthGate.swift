import ClerkKit
import ClerkKitUI
import SwiftUI

struct AuthGate: View {
    @Environment(Clerk.self) private var clerk
    @Environment(\.scenePhase) private var scenePhase

    @State private var sessionStore: AuthSessionStore = AppEnvironment.makeAuthSessionStore()

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
            AuthView(mode: .signInOrUp, isDismissable: false)
        } else {
            RootView()
                .environment(sessionStore)
        }
    }
}
