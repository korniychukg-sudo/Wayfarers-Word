import Foundation
import StoreKit

struct WayPlan {
    let id: String
    let name: String
    let price: String
    let perWeek: String?
    let savings: Int?
}

@MainActor
final class WayShop: ObservableObject {
    static let shared = WayShop()

    static let weeklyID = "com.owenfortin.kjvbiblewidgets.plus.weekly"
    static let monthlyID = "com.owenfortin.kjvbiblewidgets.plus.monthly"
    static let yearlyID = "com.owenfortin.kjvbiblewidgets.plus.yearly"
    static let lifetimeID = "com.owenfortin.kjvbiblewidgets.plus.lifetime"
    static let allIDs = [weeklyID, monthlyID, yearlyID, lifetimeID]

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

    var plans: [WayPlan] {
#if DEBUG
        if let fixture = WayShop.reviewPlans { return fixture }
#endif
        return products.map { WayPlan(id: $0.id, name: $0.displayName, price: $0.displayPrice, perWeek: perWeekPrice($0), savings: savingsPercent($0)) }
    }

#if DEBUG
    static let reviewPlans: [WayPlan]? = {
        guard ProcessInfo.processInfo.arguments.contains("-reviewPlans") else { return nil }
        return [
            WayPlan(id: weeklyID, name: "Plus Weekly", price: "$4.99", perWeek: nil, savings: nil),
            WayPlan(id: monthlyID, name: "Plus Monthly", price: "$9.99", perWeek: "$2.30", savings: 54),
            WayPlan(id: yearlyID, name: "Plus Yearly", price: "$29.99", perWeek: "$0.58", savings: 88),
            WayPlan(id: lifetimeID, name: "Plus Lifetime", price: "$39.99", perWeek: nil, savings: nil)
        ]
    }()
#endif

    func weeksIn(_ product: Product) -> Double? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return Double(period.value) / 7.0
        case .week: return Double(period.value)
        case .month: return Double(period.value) * 4.345
        case .year: return Double(period.value) * 52.143
        @unknown default: return nil
        }
    }

    func perWeekPrice(_ product: Product) -> String? {
        guard let weeks = weeksIn(product), weeks > 1.05 else { return nil }
        return (product.price / Decimal(weeks)).formatted(product.priceFormatStyle)
    }

    func savingsPercent(_ product: Product) -> Int? {
        guard let weekly = self.product(Self.weeklyID),
              let baseWeeks = weeksIn(weekly), baseWeeks > 0,
              let weeks = weeksIn(product), weeks > baseWeeks else { return nil }
        let base = weekly.price / Decimal(baseWeeks)
        let mine = product.price / Decimal(weeks)
        guard base > 0 else { return nil }
        let saved = NSDecimalNumber(decimal: (base - mine) / base).doubleValue * 100
        guard saved >= 1, saved < 100 else { return nil }
        return Int(saved.rounded())
    }

    func loadProducts() async {
#if DEBUG
        if WayShop.reviewPlans != nil { return }
#endif
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
