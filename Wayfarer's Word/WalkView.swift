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
    @State private var noteDraft = ""
    @State private var showNoteSheet = false

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

                CaravanStrip(progress: Double(store.walkedCount(journey.journey)) / Double(journey.waypoints.count))

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
                    HStack(alignment: .top, spacing: 10) {
                        Text(String(waypoint.narration.prefix(1)))
                            .font(.custom("Georgia-Bold", size: 52))
                            .foregroundColor(Parch.gold)
                            .padding(.top, -8)
                            .overlay(Rectangle().fill(Parch.gold.opacity(0.35)).frame(width: 1.2).padding(.vertical, 2), alignment: .trailing)
                            .padding(.trailing, 2)
                        Text(String(waypoint.narration.dropFirst()))
                            .font(.parchSerif(16))
                            .foregroundColor(Parch.ink)
                            .lineSpacing(5)
                    }
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
                    fieldNoteCard
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
        .overlay {
            if let j = store.celebrateJourney {
                RoadWalkedOverlay(journey: j) {
                    store.celebrateJourney = nil
                }
            }
        }
        .sheet(isPresented: $showNoteSheet) {
            FieldNoteSheet(journey: journey, waypoint: waypoint, index: index, draft: $noteDraft)
        }
    }

    private var fieldNoteCard: some View {
        Button {
            noteDraft = store.fieldNote(for: store.token(journey.journey, index)) ?? ""
            showNoteSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("FIELD NOTE")
                        .font(.parchTitle(11))
                        .foregroundColor(Parch.road)
                        .kerning(1.6)
                    Spacer()
                    WayIcon(kind: "book", size: 15, color: Parch.road.opacity(0.8))
                }
                if let note = store.fieldNote(for: store.token(journey.journey, index)) {
                    Text(note)
                        .font(.parchItalic(15))
                        .foregroundColor(Parch.ink)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Leave a line from the road — what this place looked like from where you stood.")
                        .font(.parchItalic(14))
                        .foregroundColor(Parch.inkSoft)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(RoundedRectangle(cornerRadius: 14).fill(Parch.road.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Parch.road.opacity(0.35), lineWidth: 1.1))
        }
        .buttonStyle(.plain)
    }
}

struct CaravanStrip: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = 14 + (w - 42) * CGFloat(min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                Path { p in
                    p.move(to: CGPoint(x: 4, y: 26))
                    p.addQuadCurve(to: CGPoint(x: w - 4, y: 26), control: CGPoint(x: w / 2, y: 20))
                }
                .stroke(Parch.road.opacity(0.6), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [7, 6]))
                ForEach(0..<5, id: \.self) { k in
                    Rectangle()
                        .fill(Parch.inkFaint)
                        .frame(width: 1.6, height: 7)
                        .offset(x: 4 + (w - 8) * CGFloat(k + 1) / 6, y: 8)
                }
                WayIcon(kind: "camel", size: 30, color: Parch.ink)
                    .offset(x: x - 15, y: -4)
            }
        }
        .frame(height: 40)
    }
}

struct FieldNoteSheet: View {
    @EnvironmentObject var store: WayStore
    @Environment(\.dismiss) private var dismiss
    let journey: WWJourney
    let waypoint: WWWaypoint
    let index: Int
    @Binding var draft: String

    var body: some View {
        NavigationView {
            ZStack {
                ParchBackground()
                VStack(alignment: .leading, spacing: 14) {
                    Text(waypoint.place)
                        .font(.parchTitle(18))
                        .foregroundColor(Parch.ink)
                    Text("\(journey.title) · \(waypoint.reference)")
                        .font(.parchSerif(13))
                        .foregroundColor(Parch.inkSoft)
                    TextEditor(text: $draft)
                        .font(.parchSerif(16))
                        .foregroundColor(Parch.ink)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 180, maxHeight: 300)
                        .background(RoundedRectangle(cornerRadius: 13).fill(Parch.card))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Parch.gold.opacity(0.45), lineWidth: 1.2))
                    Button {
                        store.setFieldNote(store.token(journey.journey, index), draft)
                        dismiss()
                    } label: {
                        Text("Keep this note")
                            .font(.parchTitle(16))
                            .foregroundColor(Parch.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Parch.gold))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Parch.inkSoft)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.light)
    }
}

struct RoadWalkedOverlay: View {
    let journey: WWJourney
    var onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Parch.ink.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("ROAD WALKED")
                        .font(.parchTitle(30))
                        .foregroundColor(Parch.road)
                        .kerning(3)
                    Text("\(journey.totalMiles) miles · \(journey.waypoints.count) camps")
                        .font(.parchTitle(13))
                        .foregroundColor(Parch.road.opacity(0.85))
                        .kerning(1.2)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 8).fill(Parch.paper.opacity(0.95)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Parch.road, lineWidth: 4))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Parch.road.opacity(0.5), lineWidth: 1.6).padding(-6))
                .rotationEffect(.degrees(appeared ? -7 : 12))
                .scaleEffect(appeared ? 1 : 2.6)
                .opacity(appeared ? 1 : 0)
                Text(journey.title)
                    .font(.parchTitle(26))
                    .foregroundColor(Parch.paper)
                    .multilineTextAlignment(.center)
                Text("Every camp on this road is behind you. The Atlas holds the next one.")
                    .font(.parchSerif(14))
                    .foregroundColor(Parch.paper.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button {
                    onDismiss()
                } label: {
                    Text("On to the next road")
                        .font(.parchTitle(16))
                        .foregroundColor(Parch.ink)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Parch.goldBright))
                }
                .buttonStyle(.plain)
            }
            .padding(30)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.1)) { appeared = true }
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
