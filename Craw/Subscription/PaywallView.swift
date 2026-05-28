import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    var body: some View {
        Group {
            if let product = subscriptionStore.currentProduct {
                content(product: product)
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
            if subscriptionStore.currentProduct == nil {
                viewModel.isLoadingOfferings = true
                await subscriptionStore.refresh()
                viewModel.isLoadingOfferings = false
            }
        }
    }

    private func content(product: StoreProduct) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                header
                benefitsCard
                subscriptionFounderNote
                feedbackInvitation
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.base)
        }
        .background(Theme.Palette.canvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar(product: product)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, Theme.Spacing.sm)
                .padding(.trailing, Theme.Spacing.md)
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Palette.muted)
                .frame(width: 36, height: 36)
                .background(Theme.Palette.surfaceCard)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
                )
                .crawCardShadow()
                .padding(Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    private func bottomBar(product: StoreProduct) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.trendDown)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            cta(product: product)
            restoreButton
            footer
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
        .background(
            Theme.Palette.canvas
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    Rectangle()
                        .fill(Theme.Palette.hairlineSoft)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Craw Membership")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.rausch)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Palette.rauschTint)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("A better reading habit, built with you.")
                    .font(Theme.Typography.onboardingHero)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Image("mascotCraw")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.benefits.enumerated()), id: \.offset) { index, benefit in
                benefitRow(benefit)

                if index < Self.benefits.count - 1 {
                    Divider()
                        .background(Theme.Palette.hairlineSoft)
                        .padding(.leading, 44)
                }
            }
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .crawCardShadow()
    }

    private func benefitRow(_ benefit: PaywallBenefit) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: benefit.iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 32, height: 32)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(benefit.title)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(benefit.detail)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.md)
    }

    private var subscriptionFounderNote: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                Image("mike")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Palette.canvas, lineWidth: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text("A note from Mike")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("creator of Craw")
                        .font(Theme.Typography.captionSm)
                        .foregroundStyle(Theme.Palette.muted)
                }

                Spacer()
            }

            Text(
                "I'm building Craw as a solo developer, so I want the subscription to be plain: it pays for the features that cost money to run and for the time to keep making the app better. If something would make Craw more useful for you, I still want to hear it."
            )
            .font(Theme.Typography.bodySm)
            .foregroundStyle(Theme.Palette.body)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.base)
        .background(founderNoteBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .crawCardShadow()
    }

    private var feedbackInvitation: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 32, height: 32)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text("Have an idea or something missing? I'm still listening.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var founderNoteBackground: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Palette.surfaceCard

            Circle()
                .fill(Theme.Palette.rauschTint)
                .frame(width: 96, height: 96)
                .offset(x: 36, y: -48)
        }
    }

    private static let benefits = [
        PaywallBenefit(
            iconName: "chart.line.uptrend.xyaxis",
            title: "Personal reading progress",
            detail: "Stats and trends that show what changed, not just what happened."
        ),
        PaywallBenefit(
            iconName: "sparkles",
            title: "Smarter guidance",
            detail: "Quizzes to help you memorize reading content and focus."
        ),
        PaywallBenefit(
            iconName: "flame.fill",
            title: "Community competition access",
            detail: "Streaks, competition, and small nudges to keep the habit alive."
        )
    ]

    private func cta(product: StoreProduct) -> some View {
        let price = product.localizedPriceString
        let title = viewModel.isPurchasing ? "Subscribing…" : "Subscribe — \(price) / month"
        return OnboardingPrimaryButton(title: title, isEnabled: !viewModel.isPurchasing) {
            Task { await purchase(product: product) }
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
                .padding(.vertical, Theme.Spacing.xs)
        }
        .disabled(viewModel.isRestoring || viewModel.isPurchasing)
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.xxs) {
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
    }

    private func purchase(product: StoreProduct) async {
        viewModel.errorMessage = nil
        viewModel.isPurchasing = true
        defer { viewModel.isPurchasing = false }
        do {
            try await subscriptionStore.purchase(product)
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

private struct PaywallBenefit {
    let iconName: String
    let title: String
    let detail: String
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
