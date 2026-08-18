import Foundation
import StoreKit

@MainActor
final class WayShop: ObservableObject {
    static let shared = WayShop()

    static let weeklyID = "com.wayfarersword.app.plus.weekly"
    static let yearlyID = "com.wayfarersword.app.plus.yearly"
    static let lifetimeID = "com.wayfarersword.app.plus.lifetime"
    static let allIDs = [weeklyID, yearlyID, lifetimeID]

    @Published var products: [Product] = []
    @Published var loading = false
    @Published var purchasing = false
    @Published var message: String? = nil

    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    func loadProducts() async {
        guard products.isEmpty else { return }
        loading = true
        defer { loading = false }
        do {
            let loaded = try await Product.products(for: WayShop.allIDs)
            products = WayShop.allIDs.compactMap { id in loaded.first { $0.id == id } }
        } catch {
            message = "The shop could not be reached. Abraham's Road stays free — try again any time."
        }
    }

    func purchase(_ product: Product) async {
        purchasing = true
        defer { purchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    await refreshEntitlement()
                    message = "Every road is open. Walk far."
                }
            case .userCancelled:
                break
            case .pending:
                message = "Your purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            message = "The purchase could not be completed."
        }
    }

    func restore() async {
        purchasing = true
        defer { purchasing = false }
        try? await AppStore.sync()
        await refreshEntitlement()
        message = WayStore.shared.plusUnlocked ? "Your purchases are restored." : "No previous purchase was found."
    }

    func refreshEntitlement() async {
        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue,
               WayShop.allIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        WayStore.shared.setPlus(unlocked)
    }
}
