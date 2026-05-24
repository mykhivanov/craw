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
    private(set) var currentOffering: Offering?
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
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.offering(identifier: SubscriptionEntitlement.defaultOfferingIdentifier)
                ?? offerings.current
        } catch {
            lastErrorMessage = error.localizedDescription
        }
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
        currentOffering = nil
    }

    func purchase(_ package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        apply(customerInfo: result.customerInfo)
    }

    func restore() async throws {
        let info = try await Purchases.shared.restorePurchases()
        apply(customerInfo: info)
    }

    private func apply(customerInfo: CustomerInfo) {
        status = Status.from(customerInfo: customerInfo)
    }
}

extension SubscriptionStore.Status {
    static func from(customerInfo: CustomerInfo) -> Self {
        guard let entitlement = customerInfo.entitlements[SubscriptionEntitlement.identifier] else {
            return .inactive
        }
        if entitlement.isActive {
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
        return .inactive
    }
}
