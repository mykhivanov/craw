import SwiftUI

struct ProfileSubscriptionRow: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore

    let onSubscribe: () -> Void
    let onManage: () -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(subtitle)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Spacer()
                if isInteractive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Palette.mutedSoft)
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .frame(minHeight: 72)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .opacity(isUnknown ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .accessibilityIdentifier("profile.subscription")
    }

    private func handleTap() {
        switch subscriptionStore.status {
        case .unknown: return
        case .inactive: onSubscribe()
        case .active, .inGracePeriod, .cancelled: onManage()
        }
    }

    private var isInteractive: Bool {
        if case .unknown = subscriptionStore.status { return false }
        return true
    }

    private var isUnknown: Bool {
        if case .unknown = subscriptionStore.status { return true }
        return false
    }

    private var iconName: String {
        switch subscriptionStore.status {
        case .unknown: "hourglass"
        case .inactive: "sparkle"
        case .active, .inGracePeriod: "checkmark.seal.fill"
        case .cancelled: "clock.badge.exclamationmark"
        }
    }

    private var iconColor: Color {
        switch subscriptionStore.status {
        case .unknown, .inactive: Theme.Palette.muted
        case .active, .inGracePeriod: Theme.Palette.rausch
        case .cancelled: Theme.Palette.trendDown
        }
    }

    private var title: String {
        switch subscriptionStore.status {
        case .unknown: "Subscription"
        case .inactive: "Subscribe"
        case .active, .cancelled, .inGracePeriod: "Subscription"
        }
    }

    private var subtitle: String {
        switch subscriptionStore.status {
        case .unknown: "Loading…"
        case .inactive: "Unlock the full Craw experience"
        case let .active(expiresAt):
            expiresAt.map { "Active · renews \(Self.format($0))" } ?? "Active"
        case .inGracePeriod: "Billing retry — update your payment method"
        case let .cancelled(expiresAt): "Cancelled · ends \(Self.format(expiresAt))"
        }
    }

    private static func format(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
