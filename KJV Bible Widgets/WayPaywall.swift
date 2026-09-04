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
                ScrollViewReader { proxy in
                LazyVStack(spacing: 18) {
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

                    if let ui = WayArt.hero("paul") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                LinearGradient(colors: [.clear, Parch.night.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                                    .overlay(alignment: .bottomLeading) {
                                        Label("THE COMPLETE ATLAS", systemImage: "map.fill")
                                            .font(.waySans(11, weight: .bold)).kerning(1.4)
                                            .foregroundStyle(Parch.goldBright).padding(18)
                                    }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: Parch.night.opacity(0.22), radius: 18, y: 9)
                    }

                    Text("The whole world of the Word")
                        .font(.parchTitle(29))
                        .foregroundColor(Parch.ink)
                        .multilineTextAlignment(.center)
                        .id("offer")

                    Text("Eight journeys, 79 waypoints, 7,780 miles of scripture walked place by place — from Ur of the Chaldees to the Appian Way into Rome.")
                        .font(.parchSerif(15))
                        .foregroundColor(Parch.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    VStack(spacing: 10) {
                        featureRow("All 8 journeys on interactive maps")
                        featureRow("79 waypoints with KJV readings")
                        featureRow("Cinematic historical scenes and rich reading")
                        featureRow("Map widgets that walk with you")
                    }
                    .padding(.vertical, 4)

                    if shop.plans.isEmpty {
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
                            ForEach(shop.plans, id: \.id) { plan in
                                planRow(plan)
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
                            .background(LinearGradient(colors: [Parch.sage, Parch.water], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Parch.water.opacity(0.24), radius: 14, y: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(shop.plans.isEmpty || shop.purchasing)
                    .opacity(shop.plans.isEmpty ? 0.5 : 1)

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

                    HStack(spacing: 16) {
                        Link("Terms of Use", destination: WayLinks.terms)
                        NavigationLink("Privacy Policy") { WayPrivacyView() }
                        Link("Support", destination: WayLinks.support)
                    }
                    .font(.parchSerif(12))
                    .foregroundColor(Parch.inkFaint)

                    Text("Subscriptions renew automatically until canceled in your App Store settings. The lifetime unlock is a one-time purchase.")
                        .font(.parchSerif(11))
                        .foregroundColor(Parch.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .wayResponsiveColumn(maxWidth: 720, inset: 22)
                .task { await scrollForReview(proxy) }
                }
            }
        }
        .task { await shop.loadProducts() }
        .onChange(of: store.plusUnlocked) { _, unlocked in
            if unlocked { onClose() }
        }
    }

    private func scrollForReview(_ proxy: ScrollViewProxy) async {
#if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-scrollToOffer") else { return }
        try? await Task.sleep(nanoseconds: 900_000_000)
        proxy.scrollTo("offer", anchor: .top)
#endif
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

    private func planRow(_ plan: WayPlan) -> some View {
        let isSelected = selected == plan.id
        let badge: String? = plan.id == WayShop.yearlyID ? "BEST VALUE" : (plan.id == WayShop.lifetimeID ? "ONE TIME" : nil)
        let caption: String
        switch plan.id {
        case WayShop.weeklyID: caption = "per week"
        case WayShop.monthlyID: caption = "per month"
        case WayShop.yearlyID: caption = "per year"
        default: caption = "once, forever"
        }
        let savings = plan.savings
        let perWeek = plan.perWeek
        return Button {
            selected = plan.id
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.name.isEmpty ? planName(plan.id) : plan.name)
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
                    Text(perWeek == nil ? "\(plan.price) \(caption)" : "\(plan.price) \(caption) · \(perWeek ?? "") / week")
                        .font(.parchSerif(13))
                        .foregroundColor(Parch.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if let savings {
                        Text("Save \(savings)% vs weekly")
                            .font(.parchTitle(12))
                            .foregroundColor(Parch.gold)
                    }
                }
                Spacer(minLength: 0)
                Circle()
                    .stroke(isSelected ? Parch.gold : Parch.inkFaint, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().fill(Parch.gold).frame(width: 12, height: 12).opacity(isSelected ? 1 : 0))
            }
            .padding(15)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isSelected ? Parch.gold.opacity(0.1) : Parch.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(isSelected ? Parch.gold : Parch.inkFaint.opacity(0.4), lineWidth: isSelected ? 1.8 : 1))
        }
        .buttonStyle(.plain)
    }

    private func planName(_ id: String) -> String {
        switch id {
        case WayShop.weeklyID: return "Weekly"
        case WayShop.monthlyID: return "Monthly"
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
                LazyVStack(alignment: .leading, spacing: 14) {
                    Text("Privacy Policy")
                        .font(.parchTitle(24))
                        .foregroundColor(Parch.ink)
                    Group {
                        Text("KJV Bible Widgets keeps everything on your device.")
                        Text("Your walked waypoints, miles, streaks and quiz scores live only in this app's local storage and its App Group container, which exists so the widgets can show where you stand on the road. Nothing is uploaded, collected, or shared; there are no analytics, no advertising, and no account.")
                        Text("Purchases are handled entirely by Apple through the App Store. The app never sees your payment details; it only receives Apple's confirmation that the unlock belongs to your Apple ID, which is how Restore Purchases works on a new device.")
                        Text("The one network connection the app ever makes is Apple's own StoreKit service for the purchase sheet and prices. If you never open the unlock screen, the app works entirely offline.")
                        Text("Deleting the app deletes all of your data with it.")
                    }
                    .font(.parchSerif(15))
                    .foregroundColor(Parch.inkSoft)

                    Link(destination: WayLinks.support) {
                        HStack(spacing: 8) {
                            Image(systemName: "lifepreserver.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Support and contact")
                                .font(.parchTitle(14.5))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Parch.gold)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Parch.gold.opacity(0.09)))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Parch.gold.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 22)
                .wayResponsiveColumn(maxWidth: 760, inset: 22)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WayOnboardingView: View {
    @EnvironmentObject var store: WayStore
    @State private var page = 0
    @State private var appeared = false

    var body: some View {
        Group {
            if page < 3 {
                GeometryReader { geo in
                    ZStack {
                        Parch.night
                        if let ui = WayArt.hero(onboardingMap) {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .scaleEffect(appeared ? 1 : 1.06)
                        }
                        LinearGradient(colors: [Parch.night.opacity(0.08), .clear, Parch.night.opacity(0.96)], startPoint: .top, endPoint: .bottom)

                        VStack(spacing: 0) {
                            if page > 0 {
                                HStack {
                                    Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { page -= 1 } } label: {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                                            .frame(width: 42, height: 42).background(.ultraThinMaterial, in: Circle())
                                    }
                                    Spacer()
                                }
                            }
                            Spacer()
                            VStack(spacing: 14) {
                                Image(systemName: onboardingIcon)
                                    .font(.system(size: 23, weight: .semibold)).foregroundStyle(Parch.goldBright)
                                Text(onboardingTitle)
                                    .font(.parchTitle(34)).foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.74)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(onboardingText)
                                    .font(.waySans(14)).foregroundStyle(.white.opacity(0.76)).lineSpacing(4)
                                    .multilineTextAlignment(.center)
                                HStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { k in
                                        Capsule().fill(k == page ? Parch.goldBright : Color.white.opacity(0.3))
                                            .frame(width: k == page ? 22 : 8, height: 8)
                                    }
                                }
                                .padding(.vertical, 5)
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { page += 1 }
                                } label: {
                                    HStack {
                                        Text(page == 2 ? "Set out" : "Continue")
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.waySans(16, weight: .bold)).foregroundStyle(.white)
                                    .padding(18)
                                    .background(LinearGradient(colors: [Parch.sage, Parch.water], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 24)
                            .frame(maxWidth: 680)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 14)
                        }
                        .padding(.top, geo.safeAreaInsets.top + 10)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .ignoresSafeArea()
            } else {
                NavigationStack { WayPaywallView { store.completeOnboarding() } }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { appeared = true } }
    }

    private var onboardingMap: String { page == 0 ? "conquest" : page == 1 ? "galilee" : "exodus" }
    private var onboardingIcon: String { page == 0 ? "square.grid.2x2.fill" : page == 1 ? "book.pages.fill" : "map.fill" }
    private var onboardingTitle: String { page == 0 ? "Scripture, right on\nyour Home Screen" : page == 1 ? "The complete Bible,\nalways with you" : "See the world\nbehind the Word" }
    private var onboardingText: String {
        if page == 0 { return "Create beautiful daily Bible widgets for every Home and Lock Screen. Choose a topic, theme, type style or pin a favorite verse." }
        if page == 1 { return "Read all 66 books and 31,102 verses offline. A tap on your widget opens the full chapter instantly." }
        return "Journey Atlas is your optional companion: eight richly illustrated routes place Scripture in its roads, cities and landscapes."
    }
}
