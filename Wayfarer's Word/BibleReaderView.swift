import SwiftUI
import UserNotifications

struct BibleVerse: Codable, Identifiable, Hashable {
    let number: Int
    let text: String
    var id: Int { number }
}

struct BibleChapter: Codable, Identifiable, Hashable {
    let chapter: Int
    let verses: [BibleVerse]
    var id: Int { chapter }
}

struct BibleBook: Codable, Identifiable, Hashable {
    let book: String
    let bookId: Int
    let englishName: String
    let testament: String
    let chapters: [BibleChapter]
    var id: Int { bookId }
}

private struct BibleFile: Codable { let books: [BibleBook] }

final class BibleLibrary {
    static let shared = BibleLibrary()
    let books: [BibleBook]

    private init() {
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(BibleFile.self, from: data) else {
            books = []
            return
        }
        books = file.books
    }

    func book(named name: String) -> BibleBook? { books.first { $0.englishName == name } }
}

struct BibleLibraryView: View {
    private let library = BibleLibrary.shared
    @State private var searchText = ""
    @State private var testament = "All"
    @AppStorage("bible.lastBook") private var lastBook = "John"
    @AppStorage("bible.lastChapter") private var lastChapter = 1

    private var filteredBooks: [BibleBook] {
        library.books.filter { book in
            (testament == "All" || book.testament == testament) &&
            (searchText.isEmpty || book.englishName.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .bottom) {
                        WaySectionTitle(eyebrow: "Read offline", title: "Holy Bible")
                        Spacer(minLength: 12)
                        Text("KJV")
                            .font(.waySans(11, weight: .bold))
                            .foregroundStyle(Parch.paper)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Parch.gold, in: Capsule())
                    }
                    .padding(.top, 16)

                    if let resumeBook = library.book(named: lastBook),
                       let chapter = resumeBook.chapters.first(where: { $0.chapter == lastChapter }) {
                        NavigationLink { BibleChapterReader(book: resumeBook, chapter: chapter) } label: {
                            continueCard(book: resumeBook, chapter: chapter)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 8) {
                        ForEach(["All", "OT", "NT"], id: \.self) { item in
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { testament = item }
                            } label: {
                                Text(item == "All" ? "ALL 66 BOOKS" : item == "OT" ? "OLD TESTAMENT" : "NEW TESTAMENT")
                                    .font(.waySans(10, weight: .bold))
                                    .foregroundStyle(testament == item ? Color.white : Parch.inkSoft)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(testament == item ? Parch.night : Parch.card, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                        ForEach(filteredBooks) { book in
                            NavigationLink { BibleBookView(book: book) } label: { bookCard(book) }
                                .buttonStyle(.plain)
                        }
                    }

                    Text("King James Version · available completely offline")
                        .font(.waySans(10, weight: .medium))
                        .foregroundStyle(Parch.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    Color.clear.frame(height: 74)
                }
                .wayResponsiveColumn(maxWidth: 820)
            }
        }
        .navigationBarHidden(true)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a book")
    }

    private func continueCard(book: BibleBook, chapter: BibleChapter) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let image = WayArt.hero("galilee") {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 210).clipped()
            }
            LinearGradient(colors: [.clear, Parch.night.opacity(0.96)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 7) {
                WayPill(icon: "bookmark.fill", text: "CONTINUE READING", dark: true)
                Text("\(book.englishName) \(chapter.chapter)")
                    .font(.parchTitle(28)).foregroundStyle(.white)
                Text(chapter.verses.first?.text ?? "")
                    .font(.parchItalic(13)).foregroundStyle(.white.opacity(0.76)).lineLimit(2)
            }
            .padding(18)
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Parch.night.opacity(0.2), radius: 22, y: 12)
    }

    private func bookCard(_ book: BibleBook) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Parch.night)
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Parch.goldBright)
            }
            .frame(width: 44, height: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.englishName)
                    .font(.parchTitle(17)).foregroundStyle(Parch.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text("\(book.chapters.count) chapter\(book.chapters.count == 1 ? "" : "s")")
                    .font(.waySans(10, weight: .medium)).foregroundStyle(Parch.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold)).foregroundStyle(Parch.gold)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .wayCard(radius: 18)
    }
}

struct BibleBookView: View {
    let book: BibleBook

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    WaySectionTitle(eyebrow: book.testament == "OT" ? "Old Testament" : "New Testament", title: book.englishName)
                        .padding(.top, 12)
                    Text("Choose a chapter")
                        .font(.parchItalic(14)).foregroundStyle(Parch.inkSoft)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 10)], spacing: 10) {
                        ForEach(book.chapters) { chapter in
                            NavigationLink { BibleChapterReader(book: book, chapter: chapter) } label: {
                                Text("\(chapter.chapter)")
                                    .font(.waySans(15, weight: .bold)).foregroundStyle(Parch.ink)
                                    .frame(maxWidth: .infinity).frame(height: 54)
                                    .background(Parch.card, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Parch.gold.opacity(0.22), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Color.clear.frame(height: 28)
                }
                .wayResponsiveColumn(maxWidth: 820)
            }
        }
        .navigationTitle(book.englishName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BibleChapterReader: View {
    private let library = BibleLibrary.shared
    let book: BibleBook
    let chapter: BibleChapter
    @AppStorage("bible.fontSize") private var fontSize = 18.0
    @AppStorage("bible.lastBook") private var lastBook = "John"
    @AppStorage("bible.lastChapter") private var lastChapter = 1

    private var currentBookIndex: Int? { library.books.firstIndex(where: { $0.id == book.id }) }

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("KING JAMES VERSION")
                            .font(.waySans(10, weight: .bold)).kerning(1.5).foregroundStyle(Parch.gold)
                        Text("\(book.englishName) \(chapter.chapter)")
                            .font(.parchTitle(32)).foregroundStyle(Parch.ink)
                            .lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .padding(.top, 14)
                    RoadRule()
                    VStack(alignment: .leading, spacing: 17) {
                        ForEach(chapter.verses) { verse in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(verse.number)")
                                    .font(.waySans(10, weight: .bold)).foregroundStyle(Parch.gold)
                                    .frame(width: 24, alignment: .trailing)
                                Text(verse.text)
                                    .font(.system(size: fontSize, weight: .regular, design: .serif))
                                    .foregroundStyle(Parch.ink).lineSpacing(fontSize * 0.34)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    chapterNavigation
                    Color.clear.frame(height: 36)
                }
                .wayResponsiveColumn(maxWidth: 720, inset: 22)
            }
        }
        .navigationTitle("\(book.englishName) \(chapter.chapter)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Smaller text") { fontSize = max(15, fontSize - 1) }
                    Button("Larger text") { fontSize = min(26, fontSize + 1) }
                    Button("Reset text size") { fontSize = 18 }
                } label: { Image(systemName: "textformat.size") }
            }
        }
        .onAppear {
            lastBook = book.englishName
            lastChapter = chapter.chapter
        }
    }

    @ViewBuilder private var chapterNavigation: some View {
        HStack(spacing: 12) {
            if let previous = neighbor(offset: -1) {
                NavigationLink { BibleChapterReader(book: previous.0, chapter: previous.1) } label: {
                    Label("Previous", systemImage: "arrow.left").frame(maxWidth: .infinity)
                }
                .buttonStyle(BibleNavButtonStyle())
            }
            if let next = neighbor(offset: 1) {
                NavigationLink { BibleChapterReader(book: next.0, chapter: next.1) } label: {
                    Label("Next", systemImage: "arrow.right").frame(maxWidth: .infinity)
                }
                .buttonStyle(BibleNavButtonStyle())
            }
        }
    }

    private func neighbor(offset: Int) -> (BibleBook, BibleChapter)? {
        if let chapterIndex = book.chapters.firstIndex(where: { $0.id == chapter.id }) {
            let nextChapter = chapterIndex + offset
            if book.chapters.indices.contains(nextChapter) { return (book, book.chapters[nextChapter]) }
        }
        guard let bookIndex = currentBookIndex else { return nil }
        let nextBook = bookIndex + offset
        guard library.books.indices.contains(nextBook) else { return nil }
        let target = library.books[nextBook]
        return offset < 0 ? target.chapters.last.map { (target, $0) } : target.chapters.first.map { (target, $0) }
    }
}

private struct BibleNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.waySans(12, weight: .bold))
            .foregroundStyle(configuration.isPressed ? Parch.gold : Parch.paper)
            .padding(.vertical, 13)
            .background(Parch.night.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum ScriptureThemeStyle {
    static func colors(_ theme: String) -> (background: [Color], text: Color, soft: Color, accent: Color) {
        switch theme {
        case "Midnight": return ([Parch.night, Parch.nightRaised], .white, .white.opacity(0.65), Parch.goldBright)
        case "Dawn": return ([Color(red: 0.97, green: 0.72, blue: 0.48), Color(red: 0.56, green: 0.29, blue: 0.30)], .white, .white.opacity(0.72), Color(red: 1, green: 0.90, blue: 0.68))
        case "Sage": return ([Color(red: 0.76, green: 0.82, blue: 0.72), Parch.sage], .white, .white.opacity(0.72), Color(red: 0.97, green: 0.87, blue: 0.62))
        case "Ocean": return ([Color(red: 0.16, green: 0.38, blue: 0.47), Color(red: 0.035, green: 0.13, blue: 0.18)], .white, .white.opacity(0.7), Color(red: 0.59, green: 0.85, blue: 0.86))
        default: return ([Color(red: 0.98, green: 0.96, blue: 0.91), Color(red: 0.88, green: 0.83, blue: 0.72)], Parch.ink, Parch.inkSoft, Parch.gold)
        }
    }
}

struct ScripturePreviewCard: View {
    enum Size: String, CaseIterable { case small = "Small", medium = "Medium", large = "Large" }
    let settings: ScriptureWidgetSettings
    let size: Size
    var verse: ScriptureVerse { settings.selectedVerse() }

    private var cardSize: CGSize {
        switch size {
        case .small: return CGSize(width: 172, height: 172)
        case .medium: return CGSize(width: 354, height: 172)
        case .large: return CGSize(width: 354, height: 354)
        }
    }

    var body: some View {
        let palette = ScriptureThemeStyle.colors(settings.theme)
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: palette.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(palette.accent.opacity(0.16)).frame(width: size == .large ? 240 : 150).offset(x: cardSize.width * 0.62, y: -70)
            Image(systemName: "sun.max.fill").font(.system(size: size == .large ? 92 : 60)).foregroundStyle(palette.accent.opacity(0.08)).offset(x: cardSize.width * 0.69, y: -18)
            if size == .medium { mediumContent(palette) } else { verticalContent(palette) }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.35), lineWidth: 1))
        .shadow(color: Parch.night.opacity(0.22), radius: 24, y: 14)
        .accessibilityElement(children: .combine)
    }

    private func brand(_ palette: (background: [Color], text: Color, soft: Color, accent: Color)) -> some View {
        Label(settings.showTopic ? verse.topic.uppercased() : "WAYFARER'S WORD", systemImage: settings.icon)
            .font(.waySans(9, weight: .bold)).kerning(1.1).foregroundStyle(palette.accent).lineLimit(1)
    }

    private func verticalContent(_ palette: (background: [Color], text: Color, soft: Color, accent: Color)) -> some View {
        VStack(alignment: settings.alignment == "Center" ? .center : .leading, spacing: size == .large ? 16 : 8) {
            HStack { brand(palette); Spacer(); if size == .large { Image(systemName: "bookmark").foregroundStyle(palette.accent) } }
            Spacer(minLength: 0)
            if size == .large { Image(systemName: "quote.opening").font(.system(size: 28)).foregroundStyle(palette.accent) }
            Text(size == .small ? "“\(verse.text)”" : verse.text)
                .font(.system(size: size == .large ? 25 : 16, weight: .semibold, design: settings.font == "Rounded" ? .rounded : .serif))
                .foregroundStyle(palette.text).lineLimit(size == .small ? 5 : 8).minimumScaleFactor(0.72).lineSpacing(3)
                .multilineTextAlignment(settings.alignment == "Center" ? .center : .leading)
            if settings.showReference { Text(verse.reference).font(.waySans(size == .large ? 13 : 11, weight: .bold)).foregroundStyle(palette.accent) }
            if size == .large {
                Divider().overlay(palette.accent.opacity(0.4))
                Label("Tap to read the full chapter", systemImage: "book.pages").font(.waySans(11, weight: .semibold)).foregroundStyle(palette.soft)
            }
        }.padding(size == .large ? 24 : 16)
    }

    private func mediumContent(_ palette: (background: [Color], text: Color, soft: Color, accent: Color)) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: settings.alignment == "Center" ? .center : .leading, spacing: 8) {
                brand(palette)
                Text("“\(verse.text)”").font(.system(size: 17, weight: .semibold, design: settings.font == "Rounded" ? .rounded : .serif)).foregroundStyle(palette.text).lineLimit(4).minimumScaleFactor(0.74).multilineTextAlignment(settings.alignment == "Center" ? .center : .leading)
                if settings.showReference { Text(verse.reference).font(.waySans(11, weight: .bold)).foregroundStyle(palette.accent) }
            }
            Spacer(minLength: 0)
            ZStack { Circle().fill(palette.accent.opacity(0.16)); Image(systemName: "book.pages.fill").font(.system(size: 30)).foregroundStyle(palette.accent) }.frame(width: 70, height: 70)
        }.padding(18)
    }
}

struct WidgetStudioView: View {
    @State private var settings = ScriptureWidgetSettings.load()
    @State private var previewSize: ScripturePreviewCard.Size = .medium
    @State private var saved = false
    @AppStorage("ww.dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("ww.dailyReminderHour") private var reminderHour = 8
    @AppStorage("ww.dailyReminderMinute") private var reminderMinute = 0
    private let themes = ["Parchment", "Midnight", "Dawn", "Sage", "Ocean"]
    private let topics = ["Daily", "Hope", "Peace", "Strength", "Wisdom", "Love", "Faith"]
    private let icons = ["cross.fill", "bird.fill", "heart.fill", "sun.max.fill"]

    private struct WidgetTemplate: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let settings: ScriptureWidgetSettings
    }

    private var templates: [WidgetTemplate] {
        [
            .init(id: "quiet", title: "Quiet Morning", subtitle: "Peace · serif", settings: .init(theme: "Parchment", topic: "Peace", font: "Serif", alignment: "Leading", icon: "bird.fill")),
            .init(id: "courage", title: "Daily Courage", subtitle: "Strength · bold", settings: .init(theme: "Midnight", topic: "Strength", font: "Rounded", alignment: "Leading", icon: "cross.fill")),
            .init(id: "hope", title: "New Hope", subtitle: "Hope · centered", settings: .init(theme: "Dawn", topic: "Hope", font: "Serif", alignment: "Center", icon: "sun.max.fill")),
            .init(id: "beloved", title: "Beloved", subtitle: "Love · soft", settings: .init(theme: "Sage", topic: "Love", font: "Serif", alignment: "Center", icon: "heart.fill"))
        ]
    }

    var body: some View {
        ZStack {
            ParchBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    WaySectionTitle(eyebrow: "Make scripture visible", title: "Widget Studio").padding(.top, 14)
                    Text("Build a Bible widget that feels personal. It refreshes every day and opens the complete chapter with one tap.")
                        .font(.parchItalic(15)).foregroundStyle(Parch.inkSoft).fixedSize(horizontal: false, vertical: true)

                    studioSection("START WITH A TEMPLATE", icon: "rectangle.grid.2x2.fill") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(templates) { template in
                                    templateButton(template)
                                }
                            }.padding(.vertical, 4)
                        }
                    }

                    VStack(spacing: 14) {
                        Picker("Preview size", selection: $previewSize) {
                            ForEach(ScripturePreviewCard.Size.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                        HStack {
                            Spacer(minLength: 0)
                            ScripturePreviewCard(settings: settings, size: previewSize).padding(.horizontal, 2).padding(.vertical, 12)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(16).wayCard(radius: 28)

                    studioSection("APPEARANCE", icon: "paintpalette.fill") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 11) {
                                ForEach(themes, id: \.self) { theme in themeButton(theme) }
                            }.padding(.vertical, 3)
                        }
                        Picker("Type", selection: $settings.font) { Text("Elegant serif").tag("Serif"); Text("Modern rounded").tag("Rounded") }.pickerStyle(.segmented)
                        Picker("Alignment", selection: $settings.alignment) { Text("Left aligned").tag("Leading"); Text("Centered").tag("Center") }.pickerStyle(.segmented)
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button { settings.icon = icon } label: {
                                    Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(settings.icon == icon ? .white : Parch.inkSoft).frame(maxWidth: .infinity).frame(height: 45).background(settings.icon == icon ? Parch.night : Parch.paperDeep.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    studioSection("VERSE SOURCE", icon: "text.quote") {
                        Picker("Source", selection: $settings.mode) { Text("Verse of the day").tag("Daily"); Text("Pin a verse").tag("Fixed") }.pickerStyle(.segmented)
                        if settings.mode == "Daily" {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 9)], spacing: 9) {
                                ForEach(topics, id: \.self) { topic in choiceButton(topic, selected: settings.topic == topic) { settings.topic = topic } }
                            }
                        } else {
                            Picker("Pinned verse", selection: $settings.fixedVerseID) {
                                ForEach(ScriptureVerseCatalog.all) { Text("\($0.reference) · \($0.topic)").tag($0.id) }
                            }.pickerStyle(.menu).tint(Parch.gold)
                        }
                    }

                    studioSection("DETAILS", icon: "switch.2") {
                        Toggle("Show Bible reference", isOn: $settings.showReference).tint(Parch.gold)
                        Divider()
                        Toggle("Show verse topic", isOn: $settings.showTopic).tint(Parch.gold)
                    }

                    studioSection("DAILY RHYTHM", icon: "bell.badge.fill") {
                        Toggle("Daily scripture reminder", isOn: $reminderEnabled).tint(Parch.gold)
                        if reminderEnabled {
                            DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute).tint(Parch.gold)
                            Text("A gentle reminder brings you back to today’s verse. Your widgets continue to work offline.")
                                .font(.parchItalic(12)).foregroundStyle(Parch.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Button {
                        settings.save(); updateReminder(); saved = true
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { saved = false }
                    } label: {
                        Label(saved ? "Widget updated" : "Save widget design", systemImage: saved ? "checkmark.circle.fill" : "wand.and.stars")
                            .font(.waySans(15, weight: .bold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(colors: [Parch.sage, Parch.water], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }.buttonStyle(.plain)

                    addInstructions
                    Color.clear.frame(height: 84)
                }.wayResponsiveColumn(maxWidth: 820)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: settings) { _, _ in saved = false }
    }

    private func studioSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Label(title, systemImage: icon).font(.waySans(11, weight: .bold)).kerning(1.2).foregroundStyle(Parch.gold)
            content()
        }.padding(18).wayCard()
    }

    private func themeButton(_ theme: String) -> some View {
        let colors = ScriptureThemeStyle.colors(theme)
        return Button { withAnimation(.easeOut(duration: 0.2)) { settings.theme = theme } } label: {
            VStack(spacing: 7) {
                ZStack { Circle().fill(LinearGradient(colors: colors.background, startPoint: .topLeading, endPoint: .bottomTrailing)); if settings.theme == theme { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(colors.text) } }.frame(width: 45, height: 45)
                Text(theme).font(.waySans(10, weight: .semibold)).foregroundStyle(settings.theme == theme ? Parch.gold : Parch.inkSoft)
            }.frame(width: 66)
        }.buttonStyle(.plain)
    }

    private func templateButton(_ template: WidgetTemplate) -> some View {
        let colors = ScriptureThemeStyle.colors(template.settings.theme)
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { settings = template.settings }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: colors.background, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: template.settings.icon).font(.system(size: 44, weight: .light)).foregroundStyle(colors.accent.opacity(0.22)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(12)
                    Text("“Be still, and know…”").font(.system(size: 13, weight: .semibold, design: template.settings.font == "Rounded" ? .rounded : .serif)).foregroundStyle(colors.text).lineLimit(2).padding(12)
                }.frame(width: 156, height: 104).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                Text(template.title).font(.waySans(12, weight: .bold)).foregroundStyle(Parch.ink)
                Text(template.subtitle).font(.waySans(10, weight: .medium)).foregroundStyle(Parch.inkSoft)
            }.frame(width: 156, alignment: .leading)
        }.buttonStyle(.plain)
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
        } set: { value in
            reminderHour = Calendar.current.component(.hour, from: value)
            reminderMinute = Calendar.current.component(.minute, from: value)
        }
    }

    private func updateReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["ww.daily.scripture"])
        guard reminderEnabled else { return }
        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "A quiet moment with Scripture"
            content.body = ScriptureVerseCatalog.verse(topic: settings.topic).text
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: reminderHour, minute: reminderMinute), repeats: true)
            try? await center.add(UNNotificationRequest(identifier: "ww.daily.scripture", content: content, trigger: trigger))
        }
    }

    private func choiceButton(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(text).font(.waySans(11, weight: .bold)).foregroundStyle(selected ? Color.white : Parch.inkSoft).frame(maxWidth: .infinity).padding(.vertical, 10).background(selected ? Parch.night : Parch.paperDeep.opacity(0.55), in: Capsule()) }.buttonStyle(.plain)
    }

    private var addInstructions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ADD IT TO YOUR SCREEN", systemImage: "apps.iphone").font(.waySans(11, weight: .bold)).kerning(1.2).foregroundStyle(Parch.gold)
            ForEach(Array(["Touch and hold an empty area on your Home Screen", "Tap Edit, then Add Widget", "Search Wayfarer's Word, choose a size and tap Add Widget"].enumerated()), id: \.offset) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(item.offset + 1)").font(.waySans(11, weight: .bold)).foregroundStyle(.white).frame(width: 25, height: 25).background(Parch.gold, in: Circle())
                    Text(item.element).font(.waySans(13, weight: .medium)).foregroundStyle(Parch.ink).fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Tip: long-press an added widget and choose Edit Widget to override its topic or theme. Lock Screen formats are included too.")
                .font(.parchItalic(12)).foregroundStyle(Parch.inkSoft).fixedSize(horizontal: false, vertical: true)
        }.padding(18).wayCard()
    }
}
