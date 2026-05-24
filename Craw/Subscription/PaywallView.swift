import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    var body: some View {
        Group {
            if let offering = subscriptionStore.currentOffering, let package = monthlyPackage(in: offering) {
                content(package: package)
            } else if viewModel.isLoadingOfferings {
                ProgressView()
                    .tint(Theme.Palette.rausch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Palette.canvas)
            } else {
                PaywallFallbackView { dismiss() }
            }
        }
        .task {
            if subscriptionStore.currentOffering == nil {
                viewModel.isLoadingOfferings = true
                await subscriptionStore.refresh()
                viewModel.isLoadingOfferings = false
            }
        }
    }

    private func monthlyPackage(in offering: Offering) -> Package? {
        offering.monthly ?? offering.availablePackages.first
    }

    private func content(package: Package) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                qaBlock(
                    question: "What are you paying for?",
                    answer: "AI, infrastructure, and ongoing development to make your experience best in class."
                )
                qaBlock(
                    question: "What do you get?",
                    answer: "Progress quiz to make the best out of it, book suggestions, statistics, competition."
                )
                Spacer(minLength: Theme.Spacing.lg)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.trendDown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                cta(package: package)
                restoreButton
                footer
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Palette.canvas)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.muted)
                    .padding(Theme.Spacing.base)
            }
            .accessibilityLabel("Close")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Craw Membership")
                .font(Theme.Typography.onboardingHero)
                .foregroundStyle(Theme.Palette.ink)
            Text("Unlock the full reading experience.")
                .font(Theme.Typography.bodyLg)
                .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }

    private func qaBlock(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(question)
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
            Text(answer)
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func cta(package: Package) -> some View {
        let price = package.storeProduct.localizedPriceString
        let title = viewModel.isPurchasing ? "Subscribing…" : "Subscribe — \(price) / month"
        return OnboardingPrimaryButton(title: title, isEnabled: !viewModel.isPurchasing) {
            Task { await purchase(package: package) }
        }
        .accessibilityIdentifier("paywall.subscribe")
    }

    private var restoreButton: some View {
        Button {
            Task { await restore() }
        } label: {
            Text(viewModel.isRestoring ? "Restoring…" : "Restore purchases")
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(Theme.Palette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .disabled(viewModel.isRestoring || viewModel.isPurchasing)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Subscription auto-renews monthly. Cancel anytime in Settings.")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.mutedSoft)
                .multilineTextAlignment(.center)
            HStack(spacing: Theme.Spacing.base) {
                Link("Terms", destination: URL(string: "https://craw.app/terms")!)
                Link("Privacy", destination: URL(string: "https://craw.app/privacy")!)
            }
            .font(Theme.Typography.captionSm)
            .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.sm)
    }

    private func purchase(package: Package) async {
        viewModel.errorMessage = nil
        viewModel.isPurchasing = true
        defer { viewModel.isPurchasing = false }
        do {
            try await subscriptionStore.purchase(package)
            if case .active = subscriptionStore.status { dismiss() }
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            // user cancelled — silent
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        viewModel.errorMessage = nil
        viewModel.isRestoring = true
        defer { viewModel.isRestoring = false }
        do {
            try await subscriptionStore.restore()
            if case .active = subscriptionStore.status { dismiss() }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class PaywallViewModel {
    var isPurchasing = false
    var isRestoring = false
    var isLoadingOfferings = false
    var errorMessage: String?
}

struct PaywallFallbackView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Theme.Palette.muted)
            Text("Subscriptions are temporarily unavailable")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
            Text("Please check your connection and try again in a moment.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.muted)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Close", action: onClose)
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.Palette.surfaceSoft)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }
}
