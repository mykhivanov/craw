import Foundation
import Observation
import RevenueCat

@Observable
@MainActor
final class SubscriptionStore {
    enum Status: Equatable {
        case unknown
        case inactive
        case active(expiresAt: Date?)
        case inGracePeriod
        case cancelled(expiresAt: Date)
    }

    private(set) var status: Status = .unknown
    private(set) var currentProduct: StoreProduct?
    private(set) var lastErrorMessage: String?

    init() {
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(customerInfo: info)
            }
        }
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(customerInfo: info)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        // Fetch the product directly by id instead of going through offerings.
        let products = await Purchases.shared.products([SubscriptionEntitlement.monthlyProductIdentifier])
        currentProduct = products.first
    }

    func identify(clerkUserID: String) async {
        do {
            let result = try await Purchases.shared.logIn(clerkUserID)
            apply(customerInfo: result.customerInfo)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        await refresh()
    }

    func signOut() async {
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            // RevenueCat throws if already anonymous; ignore.
        }
        status = .unknown
        currentProduct = nil
    }

    func purchase(_ product: StoreProduct) async throws {
        let result = try await Purchases.shared.purchase(product: product)
        apply(customerInfo: result.customerInfo)
    }

    func restore() async throws {
        let info = try await Purchases.shared.restorePurchases()
        apply(customerInfo: info)
    }

    private func apply(customerInfo: CustomerInfo) {
        status = Status.from(customerInfo: customerInfo)
    }

    /// True when the user currently has access to subscriber-gated features.
    /// Includes `.active` and `.inGracePeriod`; treats `.cancelled` as entitled only
    /// while the paid window has not yet elapsed.
    var isEntitled: Bool {
        switch status {
        case .active:
            true
        case .inGracePeriod:
            true
        case let .cancelled(expiresAt):
            expiresAt > Date()
        case .inactive, .unknown:
            false
        }
    }
}

extension SubscriptionStore.Status {
    static func from(customerInfo: CustomerInfo) -> Self {
        // Anchor on the product we sell, then fall back to any active entitlement. This avoids
        // depending on the exact entitlement identifier configured in the RevenueCat dashboard —
        // a mismatch there would otherwise lock out a paying user.
        let entitlement = customerInfo.entitlements.active.values.first {
            $0.productIdentifier == SubscriptionEntitlement.monthlyProductIdentifier
        } ?? customerInfo.entitlements.active.values.first

        if let entitlement {
            if entitlement.billingIssueDetectedAt != nil {
                return .inGracePeriod
            }
            if entitlement.willRenew {
                return .active(expiresAt: entitlement.expirationDate)
            }
            if let expiration = entitlement.expirationDate, expiration > Date() {
                return .cancelled(expiresAt: expiration)
            }
            return .active(expiresAt: entitlement.expirationDate)
        }

        // Last resort: the subscription product is active even though no entitlement is mapped to
        // it in the dashboard. Trust the active subscription directly.
        if customerInfo.activeSubscriptions.contains(SubscriptionEntitlement.monthlyProductIdentifier) {
            return .active(expiresAt: nil)
        }
        return .inactive
    }
}
