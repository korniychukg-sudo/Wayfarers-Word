import SwiftUI

struct WalkView: View {
    @EnvironmentObject var store: WayStore

    var body: some View {
        ZStack {
            ParchBackground()
            if let (journey, waypoint, index) = store.currentWaypoint {
                WaypointReader(journey: journey, waypoint: waypoint, index: index, isCurrent: true)
            }
        }
        .navigationBarHidden(true)
    }
}

struct WaypointReader: View {
    @EnvironmentObject var store: WayStore
    let journey: WWJourney
    let waypoint: WWWaypoint
    let index: Int
    let isCurrent: Bool
    @State private var celebrated = false

    private var walkedHere: Bool { store.isWalked(journey.journey, index) }
    private var journeyFinished: Bool { store.journeyDone(journey.journey) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                HStack {
                    Text(journey.title)
                        .font(.parchSerif(12))
                        .foregroundColor(Parch.road)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Parch.road.opacity(0.1)))
                        .overlay(Capsule().stroke(Parch.road.opacity(0.4), lineWidth: 1))
                    Spacer()
                    Text("Stop \(index + 1) of \(journey.waypoints.count)")
                        .font(.parchSerif(13))
                        .foregroundColor(Parch.inkSoft)
                }
                .padding(.top, 14)

                if let ui = WayArt.vignette(journey.journey, index) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Parch.gold.opacity(0.55), lineWidth: 1.4))
                        .shadow(color: Parch.ink.opacity(0.16), radius: 10, y: 5)
                }

                VStack(spacing: 6) {
                    Text(waypoint.place)
                        .font(.parchTitle(27))
                        .foregroundColor(Parch.ink)
                        .multilineTextAlignment(.center)
                    Text(waypoint.placeNote)
                        .font(.parchItalic(13))
                        .foregroundColor(Parch.inkSoft)
                        .multilineTextAlignment(.center)
                    if waypoint.miles > 0 {
                        Text("\(waypoint.miles) miles from the last camp")
                            .font(.parchSerif(12))
                            .foregroundColor(Parch.gold)
                    }
                }

                RoadRule()

                VStack(alignment: .leading, spacing: 12) {
                    Text("THE ROAD IN")
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.gold)
                        .kerning(1.6)
                    Text(waypoint.narration)
                        .font(.parchSerif(16))
                        .foregroundColor(Parch.ink)
                        .lineSpacing(5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Parch.card))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.inkFaint.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 12) {
                    Text(waypoint.reference.uppercased())
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.gold)
                        .kerning(1.6)
                    ForEach(Array(waypoint.verses.enumerated()), id: \.offset) { pair in
                        HStack(alignment: .top, spacing: 9) {
                            Text("\(waypoint.verseStart + pair.offset)")
                                .font(.parchTitle(11))
                                .foregroundColor(Parch.gold.opacity(0.8))
                                .frame(width: 22, alignment: .trailing)
                                .padding(.top, 4)
                            Text(pair.element)
                                .font(.parchSerif(16.5))
                                .foregroundColor(Parch.ink)
                                .lineSpacing(5)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Parch.card))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.gold.opacity(0.4), lineWidth: 1.2))

                JourneyMapView(journey: journey, walkedCount: max(store.walkedCount(journey.journey), 1))

                if walkedHere {
                    if journeyFinished && isCurrent {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                WayIcon(kind: "check", size: 16, color: Parch.gold)
                                Text("\(journey.title) is walked")
                                    .font(.parchTitle(15))
                                    .foregroundColor(Parch.gold)
                            }
                            Text("Choose the next road in the Atlas.")
                                .font(.parchSerif(13))
                                .foregroundColor(Parch.inkSoft)
                        }
                        .padding(.vertical, 12)
                    } else {
                        HStack(spacing: 8) {
                            WayIcon(kind: "check", size: 16, color: Parch.gold)
                            Text("Walked")
                                .font(.parchTitle(15))
                                .foregroundColor(Parch.gold)
                        }
                        .padding(.vertical, 12)
                    }
                } else {
                    Button {
                        withAnimation(.spring(duration: 0.5)) {
                            store.markWalked(journey.journey, index)
                            celebrated = true
                        }
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    } label: {
                        Text("Walk this stretch")
                            .font(.parchTitle(16))
                            .foregroundColor(Parch.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(RoundedRectangle(cornerRadius: 13).fill(Parch.gold))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Parch.goldBright, lineWidth: 1.4))
                    }
                    .buttonStyle(.plain)
                }

                Color.clear.frame(height: 22)
            }
            .padding(.horizontal, 18)
        }
        .overlay {
            if celebrated {
                WayConfetti()
                    .allowsHitTesting(false)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { celebrated = false }
                    }
            }
        }
    }
}

struct WayConfetti: View {
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                var seed: UInt64 = 91
                func rnd() -> Double {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return Double((seed >> 33) % 10000) / 10000.0
                }
                for _ in 0..<34 {
                    let a = rnd() * 2 * .pi
                    let speed = 90 + rnd() * 200
                    let x = size.width / 2 + cos(a) * speed * t
                    let y = size.height * 0.4 + sin(a) * speed * t + 190 * t * t
                    let s = 4 + rnd() * 6
                    let colors: [Color] = [Parch.gold, Parch.goldBright, Parch.road, Parch.water]
                    let c = colors[Int(rnd() * 3.999)]
                    ctx.opacity = max(0, 1.2 - t)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s * 0.7)), with: .color(c))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.8)) { t = 1 }
        }
    }
}
