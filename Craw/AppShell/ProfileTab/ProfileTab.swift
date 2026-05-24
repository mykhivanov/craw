import ClerkKit
import StoreKit
import SwiftData
import SwiftUI

struct ProfileTab: View {
    @Environment(Clerk.self) private var clerk
    @Environment(AuthSessionStore.self) private var sessionStore
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.modelContext) private var modelContext

    @State private var apiClient: CrawAPIClient = AppEnvironment.liveAPIClient

    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var showFeedbackSheet = false

    @State private var isSigningOut = false
    @State private var isDeleting = false
    @State private var inlineError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    ProfileUserHeader()
                    ProfileSubscriptionRow {
                        showPaywall = true
                    } onManage: {
                        openManageSubscription()
                    }
                    ProfileDeveloperQuote()
                    ProfileFeedbackSection(
                        feedback: sessionStore.cachedUser?.feedback,
                        onLeaveFeedback: { showFeedbackSheet = true }
                    )
                    ProfileSignOutRow(isSigningOut: isSigningOut) {
                        showSignOutConfirmation = true
                    }
                    ProfileDeleteAccountRow(isDeleting: isDeleting) {
                        showDeleteConfirmation = true
                    }
                    if let inlineError {
                        Text(inlineError)
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Palette.trendDown)
                            .padding(.horizontal, Theme.Spacing.xs)
                    }
                }
                .padding(.horizontal, Theme.Spacing.base)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Palette.canvas)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            "Sign out of Craw?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign out") { signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Permanently delete your account?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account, library, and reading history. This cannot be undone.")
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showFeedbackSheet) {
            LeaveFeedbackSheet(apiClient: apiClient) { updatedUser in
                sessionStore.applyUpdatedUser(updatedUser)
            } onAlreadySubmitted: {
                sessionStore.bootstrapIfNeeded()
            }
        }
    }

    private func signOut() {
        isSigningOut = true
        inlineError = nil
        Task {
            do {
                try await Clerk.shared.auth.signOut()
            } catch {
                inlineError = "Couldn't sign out. Please try again."
            }
            isSigningOut = false
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        inlineError = nil
        defer { isDeleting = false }
        do {
            try await apiClient.deleteAccount()
        } catch {
            inlineError = "Couldn't delete account. Please try again."
            return
        }
        let backendCleared = true
        do {
            try await Clerk.shared.user?.delete()
        } catch {
            if backendCleared {
                wipeLocalData()
                inlineError = "Account data removed, but couldn't finalize sign-out. Sign out manually."
            }
            return
        }
        wipeLocalData()
    }

    private func wipeLocalData() {
        do {
            try CrawModelContainer.wipeAllUserData(context: modelContext)
        } catch {
            // Best-effort wipe. Re-creating the account will overwrite stale rows.
        }
    }

    private func openManageSubscription() {
        Task {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first
            else { return }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                inlineError = "Couldn't open subscription management. Try again from Settings."
            }
        }
    }
}
