import SwiftUI

struct WayQuizQuestion {
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let explain: String
}

enum WayQuizFactory {
    static func makeRound(store: WayStore) -> [WayQuizQuestion] {
        let content = WayContent.shared
        var pool: [(WWJourney, WWWaypoint, Int)] = []
        for j in content.journeys {
            for (k, w) in j.waypoints.enumerated() where store.isWalked(j.journey, k) {
                pool.append((j, w, k))
            }
        }
        if pool.count < 10 {
            if let first = content.journeys.first {
                pool = first.waypoints.enumerated().map { (first, $0.element, $0.offset) }
            }
        }
        pool.shuffle()
        var questions: [WayQuizQuestion] = []
        var used = Set<String>()
        let allPlaces = content.journeys.flatMap { $0.waypoints.map { $0.place } }

        for (journey, waypoint, index) in pool {
            guard questions.count < 10 else { break }
            guard !used.contains(waypoint.place) else { continue }
            used.insert(waypoint.place)
            let kind = questions.count % 3
            if kind == 0 {
                var titles = Set<String>([journey.title])
                while titles.count < 4, let t = content.journeys.randomElement()?.title { titles.insert(t) }
                let options = Array(titles).shuffled()
                questions.append(WayQuizQuestion(
                    prompt: "Which road passes through \(waypoint.place)?",
                    options: options,
                    answerIndex: options.firstIndex(of: journey.title) ?? 0,
                    explain: "\(waypoint.place) is stop \(index + 1) on \(journey.title)."))
            } else if kind == 1 {
                var books = Set<String>([waypoint.book])
                while books.count < 4, let b = content.journeys.randomElement()?.waypoints.randomElement()?.book { books.insert(b) }
                let options = Array(books).shuffled()
                questions.append(WayQuizQuestion(
                    prompt: "The reading at \(waypoint.place) comes from which book?",
                    options: options,
                    answerIndex: options.firstIndex(of: waypoint.book) ?? 0,
                    explain: "At \(waypoint.place) the reading is \(waypoint.reference)."))
            } else {
                guard index + 1 < journey.waypoints.count else { continue }
                let next = journey.waypoints[index + 1]
                var wrong = Set<String>()
                while wrong.count < 3, let w = allPlaces.randomElement() {
                    if w != next.place && w != waypoint.place { wrong.insert(w) }
                }
                var options = Array(wrong)
                options.append(next.place)
                options.shuffle()
                questions.append(WayQuizQuestion(
                    prompt: "Leaving \(waypoint.place) on \(journey.title), where does the road go next?",
                    options: options,
                    answerIndex: options.firstIndex(of: next.place) ?? 0,
                    explain: "The next camp is \(next.place), \(next.miles) miles on."))
            }
        }
        return questions
    }
}

struct LoreView: View {
    @EnvironmentObject var store: WayStore

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    WaySectionTitle(eyebrow: "Learn as you travel", title: "Discover")
                        .padding(.top, 16)

                    NavigationLink {
                        WayQuizView()
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            if let ui = WayArt.hero("paul") {
                                Image(uiImage: ui).resizable().scaledToFill().frame(height: 210).clipped()
                            }
                            LinearGradient(colors: [.clear, Parch.night.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    WayPill(icon: "sparkles", text: "INTERACTIVE", dark: true)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill").font(.title2).foregroundStyle(.white)
                                }
                                Text("How well do you know the road?").font(.parchTitle(22)).foregroundStyle(.white)
                                Text(store.quizBest > 0 ? "Ten questions · best score \(store.quizBest)/10" : "Ten questions from the places you've explored")
                                    .font(.waySans(12)).foregroundStyle(.white.opacity(0.72))
                            }
                            .padding(17)
                        }
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Parch.night.opacity(0.18), radius: 18, y: 9)
                    }
                    .buttonStyle(.plain)

                    Text("THE EIGHT JOURNEYS")
                        .font(.waySans(11, weight: .bold)).foregroundStyle(Parch.gold).kerning(1.6)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 13) {
                            ForEach(store.content.journeys) { journey in
                                ZStack(alignment: .bottomLeading) {
                                    if let ui = WayArt.hero(journey.journey) {
                                        Image(uiImage: ui).resizable().scaledToFill().frame(width: 230, height: 170).clipped()
                                    }
                                    LinearGradient(colors: [.clear, Parch.night.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(journey.title).font(.parchTitle(17)).foregroundStyle(.white)
                                        Text("\(journey.waypoints.count) places · \(journey.totalMiles) mi")
                                            .font(.waySans(10, weight: .medium)).foregroundStyle(.white.opacity(0.72))
                                    }.padding(14)
                                }
                                .frame(width: 230, height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                        }
                    }
                    .contentMargins(.horizontal, 18, for: .scrollContent)

                    Text("FIELD GLOSSARY")
                        .font(.waySans(11, weight: .bold)).foregroundStyle(Parch.gold).kerning(1.6)
                        .padding(.top, 6)

                    ForEach(WayGlossary.terms) { term in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(term.term)
                                .font(.parchTitle(15))
                                .foregroundColor(Parch.ink)
                            Text(term.meaning)
                                .font(.parchSerif(14))
                                .foregroundColor(Parch.inkSoft)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .wayCard(radius: 18)
                    }
                    Color.clear.frame(height: 96)
                }
                .wayResponsiveColumn(maxWidth: 900)
            }
        }
        .navigationBarHidden(true)
    }
}

struct WayQuizView: View {
    @EnvironmentObject var store: WayStore
    @State private var questions: [WayQuizQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var chosen: Int? = nil
    @State private var finished = false

    var body: some View {
        ZStack {
            ParchBackground()
            if finished {
                resultView
            } else if questions.indices.contains(index) {
                questionView(questions[index])
            } else {
                ProgressView().onAppear { startRound() }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startRound() {
        questions = WayQuizFactory.makeRound(store: store)
        index = 0
        score = 0
        chosen = nil
        finished = false
    }

    private func questionView(_ q: WayQuizQuestion) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Question \(index + 1) of \(questions.count)")
                        .font(.parchSerif(13))
                        .foregroundColor(Parch.inkSoft)
                    Spacer()
                    Text("\(score)")
                        .font(.parchTitle(15))
                        .foregroundColor(Parch.gold)
                }
                .padding(.top, 12)

                Text(q.prompt)
                    .font(.parchTitle(20))
                    .foregroundColor(Parch.ink)
                    .lineSpacing(4)

                ForEach(Array(q.options.enumerated()), id: \.offset) { pair in
                    Button {
                        guard chosen == nil else { return }
                        chosen = pair.offset
                        if pair.offset == q.answerIndex { score += 1 }
                    } label: {
                        HStack {
                            Text(pair.element)
                                .font(.parchSerif(15.5))
                                .foregroundColor(Parch.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if let c = chosen {
                                if pair.offset == q.answerIndex {
                                    WayIcon(kind: "check", size: 15, color: Parch.gold)
                                } else if pair.offset == c {
                                    WayIcon(kind: "cross", size: 13, color: Parch.road)
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(rowFill(pair.offset, q)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(rowStroke(pair.offset, q), lineWidth: 1.4))
                    }
                    .buttonStyle(.plain)
                }

                if chosen != nil {
                    Text(q.explain)
                        .font(.parchItalic(14))
                        .foregroundColor(Parch.inkSoft)
                    Button {
                        if index + 1 < questions.count {
                            index += 1
                            chosen = nil
                        } else {
                            store.quizBest = max(store.quizBest, score)
                            store.persist()
                            finished = true
                        }
                    } label: {
                        Text(index + 1 < questions.count ? "Next" : "Finish")
                            .font(.parchTitle(16))
                            .foregroundColor(Parch.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Parch.gold))
                    }
                    .buttonStyle(.plain)
                }
                Color.clear.frame(height: 20)
            }
            .wayResponsiveColumn(maxWidth: 720)
        }
    }

    private func rowFill(_ i: Int, _ q: WayQuizQuestion) -> Color {
        guard let c = chosen else { return Parch.card }
        if i == q.answerIndex { return Parch.gold.opacity(0.13) }
        if i == c { return Parch.road.opacity(0.08) }
        return Parch.card
    }

    private func rowStroke(_ i: Int, _ q: WayQuizQuestion) -> Color {
        guard let c = chosen else { return Parch.inkFaint.opacity(0.5) }
        if i == q.answerIndex { return Parch.gold }
        if i == c { return Parch.road.opacity(0.6) }
        return Parch.inkFaint.opacity(0.4)
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            WayIcon(kind: "compass", size: 56, color: Parch.gold)
            Text("\(score) of \(questions.count)")
                .font(.parchTitle(34))
                .foregroundColor(Parch.ink)
            Text(score >= 8 ? "You know these roads like a drover." : score >= 5 ? "Your feet are learning the way." : "Walk on — the road teaches as it goes.")
                .font(.parchSerif(15))
                .foregroundColor(Parch.inkSoft)
            if store.quizBest > 0 {
                Text("Best round: \(store.quizBest)/10")
                    .font(.parchSerif(13))
                    .foregroundColor(Parch.gold)
            }
            Button {
                startRound()
            } label: {
                Text("Another round")
                    .font(.parchTitle(16))
                    .foregroundColor(Parch.paper)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Parch.gold))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
