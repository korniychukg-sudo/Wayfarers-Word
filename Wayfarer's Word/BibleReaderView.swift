import SwiftUI

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
