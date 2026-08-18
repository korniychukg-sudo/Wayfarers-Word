import SwiftUI
import StoreKit

struct WayPaywallView: View {
    @EnvironmentObject var store: WayStore
    @EnvironmentObject var shop: WayShop
    var onClose: () -> Void

    @State private var selected: String = WayShop.yearlyID

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            WayIcon(kind: "cross", size: 16, color: Parch.inkSoft)
                                .padding(10)
                                .background(Circle().fill(Parch.card))
                                .overlay(Circle().stroke(Parch.inkFaint, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    if let ui = WayArt.map("paul") {
                        Image(uiImage: ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.gold.opacity(0.6), lineWidth: 1.4))
                            .shadow(color: Parch.ink.opacity(0.18), radius: 10, y: 5)
                    }

                    Text("Open every road")
                        .font(.parchTitle(26))
                        .foregroundColor(Parch.ink)

                    Text("Eight journeys, 79 waypoints, 7,780 miles of scripture walked place by place — from Ur of the Chaldees to the Appian Way into Rome.")
                        .font(.parchSerif(15))
                        .foregroundColor(Parch.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    VStack(spacing: 10) {
                        featureRow("All 8 journeys on hand-drawn maps")
                        featureRow("79 waypoints with KJV readings")
                        featureRow("Field-sketch art for every stop")
                        featureRow("Map widgets that walk with you")
                    }
                    .padding(.vertical, 4)

                    if shop.products.isEmpty {
                        VStack(spacing: 10) {
                            if shop.loading {
                                ProgressView().padding(.vertical, 24)
                            } else {
                                Text("The shop is unreachable right now. Abraham's Road stays free, and you can return here any time from the Logbook.")
                                    .font(.parchSerif(14))
                                    .foregroundColor(Parch.inkSoft)
                                    .multilineTextAlignment(.center)
                                Button("Try again") {
                                    Task { await shop.loadProducts() }
                                }
                                .font(.parchTitle(15))
                                .foregroundColor(Parch.gold)
                            }
                        }
                        .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(shop.products, id: \.id) { product in
                                planRow(product)
                            }
                        }
                    }

                    Button {
                        if let product = shop.product(selected) {
                            Task { await shop.purchase(product) }
                        }
                    } label: {
                        HStack {
                            if shop.purchasing {
                                ProgressView().tint(Parch.paper)
                            } else {
                                Text(selected == WayShop.lifetimeID ? "Unlock Forever" : "Continue")
                                    .font(.parchTitle(17))
                            }
                        }
                        .foregroundColor(Parch.paper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Parch.gold))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Parch.goldBright, lineWidth: 1.4))
                    }
                    .buttonStyle(.plain)
                    .disabled(shop.products.isEmpty || shop.purchasing)
                    .opacity(shop.products.isEmpty ? 0.5 : 1)

                    Button {
                        Task { await shop.restore() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.parchSerif(14))
                            .foregroundColor(Parch.inkSoft)
                            .underline()
                    }
                    .buttonStyle(.plain)

                    if let msg = shop.message {
                        Text(msg)
                            .font(.parchSerif(13))
                            .foregroundColor(Parch.gold)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 18) {
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        NavigationLink("Privacy Policy") { WayPrivacyView() }
                    }
                    .font(.parchSerif(12))
                    .foregroundColor(Parch.inkFaint)

                    Text("Subscriptions renew automatically until canceled in your App Store settings. The lifetime unlock is a one-time purchase.")
                        .font(.parchSerif(11))
                        .foregroundColor(Parch.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
        }
        .task { await shop.loadProducts() }
        .onChange(of: store.plusUnlocked) { _, unlocked in
            if unlocked { onClose() }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            WayIcon(kind: "check", size: 15, color: Parch.gold)
            Text(text)
                .font(.parchSerif(14))
                .foregroundColor(Parch.ink)
            Spacer()
        }
        .padding(.horizontal, 14)
    }

    private func planRow(_ product: Product) -> some View {
        let isSelected = selected == product.id
        let badge: String? = product.id == WayShop.yearlyID ? "BEST VALUE" : (product.id == WayShop.lifetimeID ? "ONE TIME" : nil)
        let caption: String
        switch product.id {
        case WayShop.weeklyID: caption = "per week"
        case WayShop.yearlyID: caption = "per year"
        default: caption = "once, forever"
        }
        return Button {
            selected = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayName.isEmpty ? planName(product.id) : product.displayName)
                            .font(.parchTitle(15))
                            .foregroundColor(Parch.ink)
                        if let badge {
                            Text(badge)
                                .font(.parchTitle(9))
                                .foregroundColor(Parch.paper)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Parch.road))
                        }
                    }
                    Text("\(product.displayPrice) \(caption)")
                        .font(.parchSerif(13))
                        .foregroundColor(Parch.inkSoft)
                }
                Spacer()
                Circle()
                    .stroke(isSelected ? Parch.gold : Parch.inkFaint, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().fill(Parch.gold).frame(width: 12, height: 12).opacity(isSelected ? 1 : 0))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 13).fill(Parch.card))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(isSelected ? Parch.gold : Parch.inkFaint.opacity(0.6), lineWidth: isSelected ? 1.8 : 1))
        }
        .buttonStyle(.plain)
    }

    private func planName(_ id: String) -> String {
        switch id {
        case WayShop.weeklyID: return "Weekly"
        case WayShop.yearlyID: return "Yearly"
        default: return "Lifetime"
        }
    }
}

struct WayPrivacyView: View {
    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Privacy Policy")
                        .font(.parchTitle(24))
                        .foregroundColor(Parch.ink)
                    Group {
                        Text("Wayfarer's Word keeps everything on your device.")
                        Text("Your walked waypoints, miles, streaks and quiz scores live only in this app's local storage and its App Group container, which exists so the widgets can show where you stand on the road. Nothing is uploaded, collected, or shared; there are no analytics, no advertising, and no account.")
                        Text("Purchases are handled entirely by Apple through the App Store. The app never sees your payment details; it only receives Apple's confirmation that the unlock belongs to your Apple ID, which is how Restore Purchases works on a new device.")
                        Text("The one network connection the app ever makes is Apple's own StoreKit service for the purchase sheet and prices. If you never open the unlock screen, the app works entirely offline.")
                        Text("Deleting the app deletes all of your data with it.")
                    }
                    .font(.parchSerif(15))
                    .foregroundColor(Parch.inkSoft)
                }
                .padding(22)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WayOnboardingView: View {
    @EnvironmentObject var store: WayStore
    @State private var page = 0

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                ParchBackground()
                if page < 3 {
                    VStack(spacing: 0) {
                        TabView(selection: $page) {
                            introPage(map: "abraham",
                                      title: "Walk the Bible's\ngreat roads",
                                      text: "Eight real journeys on hand-drawn maps — Abraham's road out of Ur, the Exodus, David on the run, Paul across the sea to Rome.")
                                .tag(0)
                            introPage(map: "exodus",
                                      title: "Read your way\ndown the road",
                                      text: "Every waypoint holds the King James passage that happened there, a field narration of the road itself, and honest miles between stops.")
                                .tag(1)
                            introPage(map: "galilee",
                                      title: "Your caravan\nkeeps the miles",
                                      text: "Reading moves your marker down the map. Miles add up in the logbook, streaks and awards follow, and widgets carry the road to your Home Screen.")
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { k in
                                Circle()
                                    .fill(k == page ? Parch.gold : Parch.inkFaint)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.bottom, 18)

                        Button {
                            withAnimation { page += 1 }
                        } label: {
                            Text(page == 2 ? "Set out" : "Continue")
                                .font(.parchTitle(17))
                                .foregroundColor(Parch.paper)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(RoundedRectangle(cornerRadius: 13).fill(Parch.gold))
                                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Parch.goldBright, lineWidth: 1.4))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                } else {
                    WayPaywallView {
                        store.completeOnboarding()
                    }
                }
                if page > 0 && page < 3 {
                    Button {
                        withAnimation { page -= 1 }
                    } label: {
                        WayIcon(kind: "chevron", size: 15, color: Parch.inkSoft)
                            .rotationEffect(.degrees(180))
                            .padding(11)
                            .background(Circle().fill(Parch.card))
                            .overlay(Circle().stroke(Parch.inkFaint, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func introPage(map: String, title: String, text: String) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)
            if let ui = WayArt.map(map) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Parch.gold.opacity(0.6), lineWidth: 1.4))
                    .shadow(color: Parch.ink.opacity(0.2), radius: 12, y: 6)
                    .padding(.horizontal, 26)
            }
            Text(title)
                .font(.parchTitle(25))
                .foregroundColor(Parch.ink)
                .multilineTextAlignment(.center)
            Text(text)
                .font(.parchSerif(15))
                .foregroundColor(Parch.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
            Spacer(minLength: 10)
        }
    }
}
