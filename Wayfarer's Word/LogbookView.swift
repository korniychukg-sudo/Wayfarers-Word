import SwiftUI

struct LogbookView: View {
    @EnvironmentObject var store: WayStore
    @EnvironmentObject var shop: WayShop
    @State private var showPaywall = false
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    WaySectionTitle(eyebrow: "Your journey in numbers", title: "Travel Journal")
                        .padding(.top, 16)

                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 9)
                            Circle()
                                .trim(from: 0, to: CGFloat(store.milesWalked) / CGFloat(max(store.totalMiles, 1)))
                                .stroke(Parch.gold, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 2) {
                                Text("\(store.milesWalked)")
                                    .font(.parchTitle(24))
                                    .foregroundColor(.white)
                                Text("miles")
                                    .font(.parchSerif(11))
                                    .foregroundColor(.white.opacity(0.62))
                            }
                        }
                        .frame(width: 108, height: 108)

                        VStack(alignment: .leading, spacing: 10) {
                            statRow("Waypoints walked", "\(store.walked.count) of 79")
                            statRow("Current streak", "\(store.streak) day\(store.streak == 1 ? "" : "s")")
                            statRow("Roads finished", "\(store.content.journeys.filter { store.journeyDone($0.journey) }.count) of 8")
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(LinearGradient(colors: [Parch.nightRaised, Parch.night], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Parch.gold.opacity(0.24), lineWidth: 1))
                    .shadow(color: Parch.night.opacity(0.2), radius: 18, y: 9)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WALKING DAYS")
                            .font(.parchTitle(11))
                            .foregroundColor(Parch.gold)
                            .kerning(1.6)
                        let grid = store.heat()
                        VStack(spacing: 5) {
                            ForEach(Array(grid.enumerated()), id: \.offset) { row in
                                HStack(spacing: 5) {
                                    ForEach(Array(row.element.enumerated()), id: \.offset) { cell in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(cell.element ? Parch.gold : Parch.inkFaint.opacity(0.25))
                                            .frame(height: 16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                    .wayCard()

                    if !store.notedWaypoints.isEmpty {
                        Text("FIELD NOTES")
                            .font(.parchTitle(11))
                            .foregroundColor(Parch.road)
                            .kerning(1.6)
                        VStack(spacing: 10) {
                            ForEach(store.notedWaypoints, id: \.3.hashValue) { entry in
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(entry.1.place)
                                            .font(.parchTitle(13.5))
                                            .foregroundColor(Parch.ink)
                                        Spacer()
                                        Text(entry.0.title)
                                            .font(.parchSerif(11))
                                            .foregroundColor(Parch.inkSoft)
                                    }
                                    Text(entry.3)
                                        .font(.parchItalic(14))
                                        .foregroundColor(Parch.inkSoft)
                                        .lineSpacing(3)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(13)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Parch.road.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Parch.road.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }

                    Text("AWARDS")
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.gold)
                        .kerning(1.6)

                    let earned = store.earnedBadges
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                        ForEach(WayStore.badges) { badge in
                            let has = earned.contains(badge.id)
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(has ? Parch.gold.opacity(0.15) : Parch.inkFaint.opacity(0.14))
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .stroke(has ? Parch.gold : Parch.inkFaint, lineWidth: 1.6)
                                        .frame(width: 46, height: 46)
                                    Image(systemName: has ? "seal.fill" : "lock.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(has ? Parch.gold : Parch.inkFaint)
                                }
                                Text(badge.title)
                                    .font(.parchTitle(11.5))
                                    .foregroundColor(has ? Parch.ink : Parch.inkFaint)
                                    .multilineTextAlignment(.center)
                                Text(badge.detail)
                                    .font(.parchSerif(9.5))
                                    .foregroundColor(Parch.inkFaint)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .wayCard(radius: 16)
                        }
                    }

                    Text("SETTINGS")
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.gold)
                        .kerning(1.6)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        if !store.plusUnlocked {
                            settingRow(icon: "star", label: "Wayfarer Plus", detail: "Open all eight roads") {
                                showPaywall = true
                            }
                            divider
                        }
                        settingRow(icon: "restore", label: "Restore Purchases", detail: nil) {
                            Task { await shop.restore() }
                        }
                        divider
                        NavigationLink {
                            WayPrivacyView()
                        } label: {
                            settingBody(icon: "book", label: "Privacy Policy", detail: nil)
                        }
                        .buttonStyle(.plain)
                        divider
                        Link(destination: WayLinks.support) {
                            settingBody(icon: "support", label: "Support", detail: "Questions, feedback and help")
                        }
                        .buttonStyle(.plain)
                        divider
                        settingRow(icon: "cross", label: "Reset progress", detail: "Clears every mile, streak and award") {
                            confirmReset = true
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Parch.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.inkFaint.opacity(0.5), lineWidth: 1))

                    if let msg = shop.message {
                        Text(msg)
                            .font(.parchSerif(13))
                            .foregroundColor(Parch.gold)
                    }

                    Text("Wayfarer's Word 1 — scripture experienced place by place. King James text, public domain. Everything you do here stays on this device.")
                        .font(.parchSerif(12))
                        .foregroundColor(Parch.inkFaint)
                        .padding(.bottom, 100)
                }
                .wayResponsiveColumn(maxWidth: 820)
            }
        }
        .navigationBarHidden(true)
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { store.resetProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every walked waypoint, mile, streak and award will be cleared. Your purchase is never affected.")
        }
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationView {
                WayPaywallView { showPaywall = false }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private var divider: some View {
        Rectangle().fill(Parch.inkFaint.opacity(0.3)).frame(height: 1).padding(.leading, 48)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.parchSerif(13.5))
                .foregroundColor(.white.opacity(0.68))
            Spacer()
            Text(value)
                .font(.parchTitle(14))
                .foregroundColor(.white)
        }
    }

    private func settingBody(icon: String, label: String, detail: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon == "star" ? "sparkles" : icon == "restore" ? "arrow.clockwise" : icon == "cross" ? "trash" : icon == "support" ? "lifepreserver.fill" : "hand.raised.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(icon == "cross" ? Parch.road : Parch.gold)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.parchTitle(14.5))
                    .foregroundColor(Parch.ink)
                if let detail {
                    Text(detail)
                        .font(.parchSerif(12))
                        .foregroundColor(Parch.inkSoft)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Parch.inkFaint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func settingRow(icon: String, label: String, detail: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingBody(icon: icon, label: label, detail: detail)
        }
        .buttonStyle(.plain)
    }
}
