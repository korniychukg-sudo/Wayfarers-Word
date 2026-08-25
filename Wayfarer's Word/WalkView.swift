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
    @State private var appeared = false

    private var walkedHere: Bool { store.isWalked(journey.journey, index) }
    private var journeyFinished: Bool { store.journeyDone(journey.journey) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                hero
                VStack(spacing: 20) {
                    progressCard
                    storyCard
                    scriptureCard
                    JourneyMapView(journey: journey, walkedCount: max(store.walkedCount(journey.journey), 1))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Parch.ink.opacity(0.12), radius: 16, y: 8)
                    if walkedHere {
                        fieldNoteCard
                        Label(journeyFinished && isCurrent ? "Journey complete — choose a new road in Atlas" : "Today's passage completed", systemImage: "checkmark.seal.fill")
                            .font(.waySans(14, weight: .semibold))
                            .foregroundStyle(Parch.sage)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    } else {
                        completeButton
                    }
                    Color.clear.frame(height: 96)
                }
                .padding(.top, 20)
                .wayResponsiveColumn(maxWidth: 760)
                .background(ParchBackground())
            }
        }
        .background(Parch.night)
        .ignoresSafeArea(edges: .top)
        .onAppear { withAnimation(.easeOut(duration: 0.7)) { appeared = true } }
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

    private var hero: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let ui = WayArt.hero(journey.journey) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 455)
                        .clipped()
                        .scaleEffect(appeared ? 1 : 1.08)
                }
                LinearGradient(colors: [.clear, Parch.night.opacity(0.18), Parch.night.opacity(0.96)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        WayPill(icon: "figure.walk", text: "STOP \(index + 1) OF \(journey.waypoints.count)", dark: true)
                        Spacer()
                        WayPill(icon: "flame.fill", text: "\(store.streak) DAY STREAK", dark: true)
                    }
                    Text("TODAY'S JOURNEY")
                        .font(.waySans(11, weight: .bold)).kerning(2)
                        .foregroundStyle(Parch.goldBright)
                    Text(waypoint.place)
                        .font(.parchTitle(38))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Text(waypoint.placeNote)
                        .font(.parchItalic(15))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Label(waypoint.reference, systemImage: "book.closed")
                        if waypoint.miles > 0 { Label("\(waypoint.miles) miles", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
                    }
                    .font(.waySans(12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                }
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
            }
            .frame(width: geometry.size.width, height: 455)
        }
        .frame(height: 455)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(journey.title).font(.waySans(14, weight: .bold)).foregroundStyle(Parch.ink)
                    Text("Your path through this journey").font(.waySans(12)).foregroundStyle(Parch.inkSoft)
                }
                Spacer()
                Text("\(Int(Double(store.walkedCount(journey.journey)) / Double(journey.waypoints.count) * 100))%")
                    .font(.waySans(19, weight: .bold)).foregroundStyle(Parch.gold)
            }
            ProgressView(value: Double(store.walkedCount(journey.journey)), total: Double(journey.waypoints.count))
                .tint(Parch.gold)
                .scaleEffect(x: 1, y: 1.5)
            HStack {
                Label("\(store.walkedCount(journey.journey)) completed", systemImage: "checkmark.circle")
                Spacer()
                Text("\(journey.waypoints.count - store.walkedCount(journey.journey)) ahead")
            }
            .font(.waySans(11, weight: .medium)).foregroundStyle(Parch.inkSoft)
        }
        .padding(17)
        .wayCard()
    }

    private var storyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("THE ROAD INTO \(waypoint.place.uppercased())", systemImage: "wind")
                .font(.waySans(11, weight: .bold)).kerning(1.2).foregroundStyle(Parch.gold)
            Text(waypoint.narration)
                .font(.parchSerif(17)).foregroundStyle(Parch.ink).lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(19)
        .wayCard()
    }

    private var scriptureCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label(waypoint.reference.uppercased(), systemImage: "text.book.closed.fill")
                    .font(.waySans(11, weight: .bold)).kerning(1.2).foregroundStyle(Parch.gold)
                Spacer()
                Image(systemName: "quote.opening").foregroundStyle(Parch.gold.opacity(0.45))
            }
            ForEach(Array(waypoint.verses.enumerated()), id: \.offset) { pair in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(waypoint.verseStart + pair.offset)")
                        .font(.waySans(10, weight: .bold)).foregroundStyle(Parch.gold)
                        .frame(width: 20, alignment: .trailing)
                    Text(pair.element)
                        .font(.parchSerif(17)).foregroundStyle(Color.white.opacity(0.9)).lineSpacing(6)
                }
            }
        }
        .padding(19)
        .background(
            LinearGradient(colors: [Parch.nightRaised, Parch.night], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .environment(\.colorScheme, .dark)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Parch.gold.opacity(0.28), lineWidth: 1))
        .shadow(color: Parch.night.opacity(0.22), radius: 18, y: 9)
    }

    private var completeButton: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                store.markWalked(journey.journey, index)
                celebrated = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Complete today's passage").font(.waySans(16, weight: .bold))
                    Text("Move your marker to the next stop").font(.waySans(11)).opacity(0.72)
                }
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(LinearGradient(colors: [Parch.sage, Parch.water], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Parch.water.opacity(0.28), radius: 16, y: 9)
        }
        .buttonStyle(.plain)
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
                    Image(systemName: "square.and.pencil").foregroundStyle(Parch.road)
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
            .padding(17)
            .wayCard()
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
