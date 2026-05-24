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
                founderNote
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
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
            Text(answer)
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(qaBlockBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .crawCardShadow()
    }

    private var qaBlockBackground: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Palette.surfaceCard

            Circle()
                .fill(Theme.Palette.rauschTint)
                .frame(width: 120, height: 120)
                .offset(x: 34, y: -52)

            LinearGradient(
                colors: [
                    Theme.Palette.rauschTint.opacity(0.55),
                    Theme.Palette.canvas
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var founderNote: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            founderNoteHeader
            founderNoteBody

            Divider()
                .background(Theme.Palette.hairlineSoft)

            founderSignatureRow
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
        .background(founderNoteBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .crawCardShadow()
    }

    private var founderNoteHeader: some View {
        HStack(alignment: .top) {
            Text("Founder note")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.rausch)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Palette.rauschTint)
                .clipShape(Capsule())

            Spacer(minLength: Theme.Spacing.base)

            Image(systemName: "quote.opening")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.Palette.rausch)
                .accessibilityHidden(true)
        }
    }

    private var founderNoteBody: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.base) {
            Text("I didn't want to flood this page with marketing.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(
                "If you're deciding whether to subscribe, you only need answers to two questions — they're right below this note."
            )
            .font(Theme.Typography.bodyLg)
            .foregroundStyle(Theme.Palette.ink)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)

            Text(
                "Thank you for supporting the development. Every subscription helps me keep building Craw and grows the readers' community around it. I genuinely believe we can make this community big — and have fun doing it together."
            )
            .font(Theme.Typography.bodyMd)
            .foregroundStyle(Theme.Palette.body)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var founderSignatureRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image("mike")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.Palette.canvas, lineWidth: 3))
                .crawCardShadow()

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Mike")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("creator of Craw")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
            }

            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 38, height: 38)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
    }

    private var founderNoteBackground: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Palette.surfaceCard

            Circle()
                .fill(Theme.Palette.rauschTint)
                .frame(width: 150, height: 150)
                .offset(x: 58, y: -58)
        }
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
