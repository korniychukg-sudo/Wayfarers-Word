import WidgetKit
import SwiftUI
import AppIntents

enum ScriptureThemeIntent: String, AppEnum {
    case app = "App settings", parchment = "Parchment", midnight = "Midnight", dawn = "Dawn", sage = "Sage", ocean = "Ocean"
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Theme")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .app: "Use app settings", .parchment: "Parchment", .midnight: "Midnight", .dawn: "Dawn", .sage: "Sage", .ocean: "Ocean"
    ]
}

enum ScriptureTopicIntent: String, AppEnum {
    case app = "App settings", daily = "Daily", hope = "Hope", peace = "Peace", strength = "Strength", wisdom = "Wisdom", love = "Love", faith = "Faith"
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Verse topic")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .app: "Use app settings", .daily: "Verse of the day", .hope: "Hope", .peace: "Peace", .strength: "Strength", .wisdom: "Wisdom", .love: "Love", .faith: "Faith"
    ]
}

enum ScriptureModeIntent: String, AppEnum {
    case app = "App settings", daily = "Daily", fixed = "Fixed"
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Verse source")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .app: "Use app settings", .daily: "Daily rotation", .fixed: "Pinned verse from app"
    ]
}

struct ScriptureWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Daily Scripture"
    static var description = IntentDescription("Choose the verse, topic and appearance shown on your Home or Lock Screen.")
    @Parameter(title: "Theme", default: .app) var theme: ScriptureThemeIntent
    @Parameter(title: "Verse topic", default: .app) var topic: ScriptureTopicIntent
    @Parameter(title: "Verse source", default: .app) var mode: ScriptureModeIntent
    @Parameter(title: "Show reference", default: true) var showReference: Bool
}

struct ScriptureEntry: TimelineEntry {
    let date: Date
    let verse: ScriptureVerse
    let settings: ScriptureWidgetSettings
}

struct ScriptureProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ScriptureEntry {
        ScriptureEntry(date: Date(), verse: ScriptureVerseCatalog.all[0], settings: .init())
    }

    func snapshot(for configuration: ScriptureWidgetIntent, in context: Context) async -> ScriptureEntry {
        entry(for: configuration, date: Date())
    }

    func timeline(for configuration: ScriptureWidgetIntent, in context: Context) async -> Timeline<ScriptureEntry> {
        let now = Date()
        let next = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 2), matchingPolicy: .nextTime) ?? now.addingTimeInterval(21600)
        return Timeline(entries: [entry(for: configuration, date: now)], policy: .after(next))
    }

    private func entry(for configuration: ScriptureWidgetIntent, date: Date) -> ScriptureEntry {
        var settings = ScriptureWidgetSettings.load()
        if configuration.theme != .app { settings.theme = configuration.theme.rawValue }
        if configuration.topic != .app { settings.topic = configuration.topic.rawValue }
        if configuration.mode != .app { settings.mode = configuration.mode.rawValue }
        settings.showReference = configuration.showReference
        return ScriptureEntry(date: date, verse: settings.selectedVerse(date: date), settings: settings)
    }
}

struct ScriptureWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WayShared.scriptureKind, intent: ScriptureWidgetIntent.self, provider: ScriptureProvider()) { entry in
            ScriptureWidgetView(entry: entry)
                .containerBackground(for: .widget) { ScriptureWidgetBackground(theme: entry.settings.theme) }
                .widgetURL(entry.verse.deepLink)
        }
        .configurationDisplayName("Daily Scripture")
        .description("Read a daily verse and open its full Bible chapter. Customize topic, style and source.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

@main
struct KJVBibleWidgetsBundle: WidgetBundle {
    var body: some Widget { ScriptureWidget() }
}
