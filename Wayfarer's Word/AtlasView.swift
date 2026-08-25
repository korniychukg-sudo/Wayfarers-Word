import SwiftUI

struct AtlasView: View {
    @EnvironmentObject var store: WayStore
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            ParchBackground()
            GeometryReader { proxy in
                let columnWidth = min(760, max(0, proxy.size.width - 36))
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .bottom, spacing: 16) {
                            WaySectionTitle(eyebrow: "Explore the world", title: "Journey Atlas")
                                .layoutPriority(1)
                            Spacer(minLength: 8)
                            journeyMetric
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            WaySectionTitle(eyebrow: "Explore the world", title: "Journey Atlas")
                            journeyMetric
                        }
                    }
                    .padding(.top, 16)

                    HStack(spacing: 8) {
                        WayPill(icon: "map.fill", text: "8 JOURNEYS")
                        WayPill(icon: "mappin.and.ellipse", text: "79 PLACES")
                        WayPill(icon: "clock.fill", text: "OFFLINE")
                    }

                    ForEach(store.content.journeys) { journey in
                        journeyCard(journey, width: columnWidth)
                    }
                    Color.clear.frame(height: 22)
                    }
                    .frame(width: columnWidth)
                    .frame(width: proxy.size.width)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywall) {
            NavigationView {
                WayPaywallView { showPaywall = false }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    @ViewBuilder
    private func journeyCard(_ journey: WWJourney, width: CGFloat) -> some View {
        let unlocked = store.isUnlocked(journey.journey)
        let walked = store.walkedCount(journey.journey)
        let done = walked == journey.waypoints.count
        if unlocked {
            NavigationLink {
                JourneyDetailView(journey: journey)
            } label: {
                cardBody(journey, walked: walked, done: done, locked: false, width: width)
            }
            .buttonStyle(.plain)
            .frame(width: width)
        } else {
            Button {
                showPaywall = true
            } label: {
                cardBody(journey, walked: walked, done: done, locked: true, width: width)
            }
            .buttonStyle(.plain)
            .frame(width: width)
        }
    }

    private func cardBody(_ journey: WWJourney, walked: Int, done: Bool, locked: Bool, width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let ui = WayArt.hero(journey.journey) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: 290)
                        .clipped()
                        .saturation(locked ? 0.55 : 1)
            }
            LinearGradient(colors: [.clear, Parch.night.opacity(0.2), Parch.night.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                .frame(width: width, height: 290)
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    if done { WayPill(icon: "checkmark.seal.fill", text: "COMPLETED", dark: true) }
                    else if locked { WayPill(icon: "lock.fill", text: "WAYFARER PLUS", dark: true) }
                    else { WayPill(icon: "figure.walk", text: "YOUR FIRST ROAD", dark: true) }
                    Spacer()
                    Image(systemName: locked ? "lock.fill" : "arrow.up.right")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34).background(.ultraThinMaterial, in: Circle())
                }
                Text(journey.title)
                    .font(.parchTitle(25))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(journey.subtitle)
                    .font(.parchItalic(13))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Label("\(journey.totalMiles) mi", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    Label("\(journey.waypoints.count) stops", systemImage: "mappin.and.ellipse")
                    Spacer()
                    Text("\(walked)/\(journey.waypoints.count)")
                }
                .font(.waySans(11, weight: .semibold)).foregroundStyle(.white.opacity(0.78))
                ProgressView(value: Double(walked), total: Double(journey.waypoints.count)).tint(Parch.goldBright)
            }
            .frame(width: max(0, width - 36), alignment: .leading)
            .padding(18)
        }
        .frame(width: width, height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: Parch.night.opacity(0.18), radius: 20, y: 10)
    }

    private var journeyMetric: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(store.milesWalked)")
                .font(.waySans(22, weight: .bold))
                .foregroundStyle(Parch.gold)
                .lineLimit(1)
            Text("of \(store.totalMiles) miles")
                .font(.waySans(10, weight: .medium))
                .foregroundStyle(Parch.inkSoft)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct JourneyDetailView: View {
    @EnvironmentObject var store: WayStore
    let journey: WWJourney
    @State private var tappedIndex: Int? = nil
    @State private var tapActive = false

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text(journey.title)
                        .font(.parchTitle(26))
                        .foregroundColor(Parch.ink)
                    Text(journey.subtitle)
                        .font(.parchItalic(14))
                        .foregroundColor(Parch.inkSoft)

                    JourneyMapView(journey: journey, walkedCount: max(store.walkedCount(journey.journey), 1))
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture(coordinateSpace: .local) { location in
                                        let fx = location.x / geo.size.width
                                        let fy = location.y / geo.size.height
                                        var best: (Int, Double)? = nil
                                        for (k, w) in journey.waypoints.enumerated() {
                                            let d = hypot(fx - w.x, fy - w.y)
                                            if d < 0.09 && (best == nil || d < best!.1) {
                                                best = (k, d)
                                            }
                                        }
                                        if let hit = best {
                                            let reachable = store.isWalked(journey.journey, hit.0) || hit.0 == store.nextIndex(journey.journey)
                                            if reachable {
                                                tappedIndex = hit.0
                                                tapActive = true
                                            }
                                        }
                                    }
                            }
                        )

                    Text("Tap a camp on the map to open it.")
                        .font(.parchItalic(12))
                        .foregroundColor(Parch.inkFaint)
                        .frame(maxWidth: .infinity)

                    if store.activeJourney != journey.journey {
                        Button {
                            store.activeJourney = journey.journey
                            store.persist()
                        } label: {
                            Text("Make this my road")
                                .font(.parchTitle(15))
                                .foregroundColor(Parch.paper)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Parch.gold))
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            WayIcon(kind: "boot", size: 16, color: Parch.gold)
                            Text("This is your current road")
                                .font(.parchTitle(13.5))
                                .foregroundColor(Parch.gold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }

                    Text(journey.essay)
                        .font(.parchSerif(15.5))
                        .foregroundColor(Parch.ink)
                        .lineSpacing(5)
                        .padding(15)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Parch.card))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.inkFaint.opacity(0.5), lineWidth: 1))

                    Text("WAYPOINTS")
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.gold)
                        .kerning(1.6)

                    VStack(spacing: 0) {
                        ForEach(Array(journey.waypoints.enumerated()), id: \.offset) { pair in
                            waypointRow(pair.offset, pair.element)
                            if pair.offset != journey.waypoints.count - 1 {
                                Rectangle()
                                    .fill(Parch.inkFaint.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.leading, 46)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Parch.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.inkFaint.opacity(0.5), lineWidth: 1))

                    Color.clear.frame(height: 22)
                }
                .wayResponsiveColumn(maxWidth: 820)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $tapActive) {
            if let idx = tappedIndex {
                NavigationView {
                    ZStack {
                        ParchBackground()
                        WaypointReader(journey: journey, waypoint: journey.waypoints[idx], index: idx, isCurrent: false)
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { tapActive = false }
                                .foregroundColor(Parch.inkSoft)
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .preferredColorScheme(.light)
            }
        }
    }

    @ViewBuilder
    private func waypointRow(_ index: Int, _ waypoint: WWWaypoint) -> some View {
        let walked = store.isWalked(journey.journey, index)
        let next = store.nextIndex(journey.journey)
        let reachable = walked || index == next
        if reachable {
            NavigationLink {
                ZStack {
                    ParchBackground()
                    WaypointReader(journey: journey, waypoint: waypoint, index: index, isCurrent: false)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                rowBody(index, waypoint, walked: walked, dim: false)
            }
            .buttonStyle(.plain)
        } else {
            rowBody(index, waypoint, walked: walked, dim: true)
        }
    }

    private func rowBody(_ index: Int, _ waypoint: WWWaypoint, walked: Bool, dim: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(walked ? Parch.gold : Parch.inkFaint, lineWidth: 1.6)
                    .frame(width: 30, height: 30)
                if walked {
                    Circle().fill(Parch.gold.opacity(0.16)).frame(width: 30, height: 30)
                    WayIcon(kind: "check", size: 13, color: Parch.gold)
                } else {
                    Text("\(index + 1)")
                        .font(.parchSerif(11))
                        .foregroundColor(Parch.inkFaint)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(waypoint.place)
                    .font(.parchTitle(14.5))
                    .foregroundColor(Parch.ink)
                Text("\(waypoint.reference)\(waypoint.miles > 0 ? " · \(waypoint.miles) mi" : "")")
                    .font(.parchSerif(12))
                    .foregroundColor(Parch.inkSoft)
            }
            Spacer()
            WayIcon(kind: "chevron", size: 13, color: Parch.inkFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .opacity(dim ? 0.5 : 1)
    }
}
