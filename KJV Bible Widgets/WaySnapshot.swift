import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WayShared {
    static let groupID = "group.com.kjvbiblewidgets.app"
    static let snapshotKey = "ww.widget.snapshot"
    static let queueKey = "ww.widget.queue"
    static let roadKind = "KJVBibleRoad"
    static let milesKind = "KJVBibleMiles"
    static let scriptureKind = "KJVBibleScripture"
    static let widgetSettingsKey = "ww.scripture.settings.v1"
}

struct ScriptureVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verse: Int
    let text: String
    let topic: String

    var reference: String { "\(book) \(chapter):\(verse)" }
    var deepLink: URL? {
        var parts = URLComponents()
        parts.scheme = "kjvbiblewidgets"
        parts.host = "bible"
        parts.queryItems = [
            URLQueryItem(name: "book", value: book),
            URLQueryItem(name: "chapter", value: String(chapter))
        ]
        return parts.url
    }
}

enum ScriptureVerseCatalog {
    static let all: [ScriptureVerse] = [
        .init(id: "john-3-16", book: "John", chapter: 3, verse: 16, text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.", topic: "Love"),
        .init(id: "psalm-23-1", book: "Psalms", chapter: 23, verse: 1, text: "The Lord is my shepherd; I shall not want.", topic: "Peace"),
        .init(id: "philippians-4-13", book: "Philippians", chapter: 4, verse: 13, text: "I can do all things through Christ which strengtheneth me.", topic: "Strength"),
        .init(id: "proverbs-3-5", book: "Proverbs", chapter: 3, verse: 5, text: "Trust in the Lord with all thine heart; and lean not unto thine own understanding.", topic: "Faith"),
        .init(id: "isaiah-41-10", book: "Isaiah", chapter: 41, verse: 10, text: "Fear thou not; for I am with thee: be not dismayed; for I am thy God.", topic: "Hope"),
        .init(id: "jeremiah-29-11", book: "Jeremiah", chapter: 29, verse: 11, text: "For I know the thoughts that I think toward you, saith the Lord, thoughts of peace, and not of evil.", topic: "Hope"),
        .init(id: "psalm-46-10", book: "Psalms", chapter: 46, verse: 10, text: "Be still, and know that I am God.", topic: "Peace"),
        .init(id: "romans-8-28", book: "Romans", chapter: 8, verse: 28, text: "And we know that all things work together for good to them that love God.", topic: "Hope"),
        .init(id: "joshua-1-9", book: "Joshua", chapter: 1, verse: 9, text: "Be strong and of a good courage; be not afraid, neither be thou dismayed: for the Lord thy God is with thee.", topic: "Strength"),
        .init(id: "matthew-11-28", book: "Matthew", chapter: 11, verse: 28, text: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.", topic: "Peace"),
        .init(id: "1-corinthians-13-4", book: "1 Corinthians", chapter: 13, verse: 4, text: "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself.", topic: "Love"),
        .init(id: "psalm-119-105", book: "Psalms", chapter: 119, verse: 105, text: "Thy word is a lamp unto my feet, and a light unto my path.", topic: "Wisdom"),
        .init(id: "james-1-5", book: "James", chapter: 1, verse: 5, text: "If any of you lack wisdom, let him ask of God, that giveth to all men liberally.", topic: "Wisdom"),
        .init(id: "hebrews-11-1", book: "Hebrews", chapter: 11, verse: 1, text: "Now faith is the substance of things hoped for, the evidence of things not seen.", topic: "Faith"),
        .init(id: "psalm-34-8", book: "Psalms", chapter: 34, verse: 8, text: "O taste and see that the Lord is good: blessed is the man that trusteth in him.", topic: "Faith"),
        .init(id: "romans-12-12", book: "Romans", chapter: 12, verse: 12, text: "Rejoicing in hope; patient in tribulation; continuing instant in prayer.", topic: "Hope"),
        .init(id: "isaiah-40-31", book: "Isaiah", chapter: 40, verse: 31, text: "They that wait upon the Lord shall renew their strength; they shall mount up with wings as eagles.", topic: "Strength"),
        .init(id: "colossians-3-14", book: "Colossians", chapter: 3, verse: 14, text: "And above all these things put on charity, which is the bond of perfectness.", topic: "Love"),
        .init(id: "proverbs-16-9", book: "Proverbs", chapter: 16, verse: 9, text: "A man's heart deviseth his way: but the Lord directeth his steps.", topic: "Wisdom"),
        .init(id: "2-corinthians-5-7", book: "2 Corinthians", chapter: 5, verse: 7, text: "For we walk by faith, not by sight.", topic: "Faith")
    ]

    static func verse(topic: String, date: Date = Date()) -> ScriptureVerse {
        let pool = topic == "Daily" ? all : all.filter { $0.topic == topic }
        let source = pool.isEmpty ? all : pool
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return source[(day - 1) % source.count]
    }

    static func verse(id: String) -> ScriptureVerse { all.first { $0.id == id } ?? all[0] }
}

struct ScriptureWidgetSettings: Codable, Equatable {
    var theme = "Parchment"
    var topic = "Daily"
    var mode = "Daily"
    var fixedVerseID = "john-3-16"
    var font = "Serif"
    var alignment = "Leading"
    var icon = "cross.fill"
    var showReference = true
    var showTopic = true

    init(theme: String = "Parchment", topic: String = "Daily", mode: String = "Daily", fixedVerseID: String = "john-3-16", font: String = "Serif", alignment: String = "Leading", icon: String = "cross.fill", showReference: Bool = true, showTopic: Bool = true) {
        self.theme = theme
        self.topic = topic
        self.mode = mode
        self.fixedVerseID = fixedVerseID
        self.font = font
        self.alignment = alignment
        self.icon = icon
        self.showReference = showReference
        self.showTopic = showTopic
    }

    private enum CodingKeys: String, CodingKey { case theme, topic, mode, fixedVerseID, font, alignment, icon, showReference, showTopic }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? "Parchment"
        topic = try values.decodeIfPresent(String.self, forKey: .topic) ?? "Daily"
        mode = try values.decodeIfPresent(String.self, forKey: .mode) ?? "Daily"
        fixedVerseID = try values.decodeIfPresent(String.self, forKey: .fixedVerseID) ?? "john-3-16"
        font = try values.decodeIfPresent(String.self, forKey: .font) ?? "Serif"
        alignment = try values.decodeIfPresent(String.self, forKey: .alignment) ?? "Leading"
        icon = try values.decodeIfPresent(String.self, forKey: .icon) ?? "cross.fill"
        showReference = try values.decodeIfPresent(Bool.self, forKey: .showReference) ?? true
        showTopic = try values.decodeIfPresent(Bool.self, forKey: .showTopic) ?? true
    }

    static func load() -> ScriptureWidgetSettings {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID),
              let data = defaults.data(forKey: WayShared.widgetSettingsKey),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return .init() }
        return value
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: WayShared.widgetSettingsKey)
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }

    func selectedVerse(date: Date = Date()) -> ScriptureVerse {
        mode == "Fixed" ? ScriptureVerseCatalog.verse(id: fixedVerseID) : ScriptureVerseCatalog.verse(topic: topic, date: date)
    }
}

struct WaySnapshotData: Codable {
    let journeyID: String
    let journeyTitle: String
    let waypointIndex: Int
    let place: String
    let reference: String
    let firstVerse: String
    let markerX: Double
    let markerY: Double
    let walkedInJourney: Int
    let journeyWaypoints: Int
    let milesWalked: Int
    let walkedToday: Bool
    let streak: Int

    static func load() -> WaySnapshotData? {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID),
              let data = defaults.data(forKey: WayShared.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WaySnapshotData.self, from: data)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: WayShared.snapshotKey)
    }
}

enum WayQueue {
    static func push(_ token: String) {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID) else { return }
        var arr = defaults.array(forKey: WayShared.queueKey) as? [String] ?? []
        arr.append(token)
        defaults.set(arr, forKey: WayShared.queueKey)
    }

    static func drain() -> [String] {
        guard let defaults = UserDefaults(suiteName: WayShared.groupID) else { return [] }
        let arr = defaults.array(forKey: WayShared.queueKey) as? [String] ?? []
        defaults.removeObject(forKey: WayShared.queueKey)
        return arr
    }
}
