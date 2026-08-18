import SwiftUI

struct AtlasView: View {
    @EnvironmentObject var store: WayStore
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Atlas")
                            .font(.parchTitle(30))
                            .foregroundColor(Parch.ink)
                        Text("\(store.milesWalked) of \(store.totalMiles) miles walked")
                            .font(.parchSerif(14))
                            .foregroundColor(Parch.inkSoft)
                    }
                    .padding(.top, 12)

                    ForEach(store.content.journeys) { journey in
                        journeyCard(journey)
                    }
                    Color.clear.frame(height: 22)
                }
                .padding(.horizontal, 18)
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
    private func journeyCard(_ journey: WWJourney) -> some View {
        let unlocked = store.isUnlocked(journey.journey)
        let walked = store.walkedCount(journey.journey)
        let done = walked == journey.waypoints.count
        if unlocked {
            NavigationLink {
                JourneyDetailView(journey: journey)
            } label: {
                cardBody(journey, walked: walked, done: done, locked: false)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                showPaywall = true
            } label: {
                cardBody(journey, walked: walked, done: done, locked: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func cardBody(_ journey: WWJourney, walked: Int, done: Bool, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let ui = WayArt.map(journey.journey) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                        .saturation(locked ? 0.4 : 1)
                        .opacity(locked ? 0.6 : 1)
                }
                if locked {
                    VStack(spacing: 6) {
                        WayIcon(kind: "lock", size: 30, color: Parch.gold)
                        Text("Unlock every road")
                            .font(.parchTitle(13))
                            .foregroundColor(Parch.ink)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Parch.card.opacity(0.92)))
                }
                if done {
                    VStack(spacing: 2) {
                        Text("ROAD WALKED")
                            .font(.parchTitle(17))
                            .foregroundColor(Parch.road)
                            .kerning(2)
                        Text("\(journey.totalMiles) MILES")
                            .font(.parchTitle(9))
                            .foregroundColor(Parch.road.opacity(0.85))
                            .kerning(1.4)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Parch.paper.opacity(0.55)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Parch.road, lineWidth: 2.6))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Parch.road.opacity(0.5), lineWidth: 1.2).padding(-4))
                    .rotationEffect(.degrees(-9))
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(journey.title)
                        .font(.parchTitle(17))
                        .foregroundColor(Parch.ink)
                    Spacer()
                    if done {
                        WayIcon(kind: "check", size: 15, color: Parch.gold)
                    }
                    Text("\(walked)/\(journey.waypoints.count)")
                        .font(.parchSerif(13))
                        .foregroundColor(done ? Parch.gold : Parch.inkSoft)
                }
                Text(journey.subtitle)
                    .font(.parchItalic(13))
                    .foregroundColor(Parch.inkSoft)
                ZStack(alignment: .leading) {
                    Capsule().fill(Parch.inkFaint.opacity(0.35)).frame(height: 4)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Parch.gold)
                            .frame(width: geo.size.width * CGFloat(Double(walked) / Double(journey.waypoints.count)), height: 4)
                    }
                    .frame(height: 4)
                }
                Text("\(journey.totalMiles) miles · \(journey.waypoints.count) waypoints")
                    .font(.parchSerif(11.5))
                    .foregroundColor(Parch.inkFaint)
            }
            .padding(13)
        }
        .background(RoundedRectangle(cornerRadius: 15).fill(Parch.card))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Parch.inkFaint.opacity(0.5), lineWidth: 1))
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
                VStack(alignment: .leading, spacing: 16) {
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
                .padding(.horizontal, 18)
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
