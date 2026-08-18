import WidgetKit
import SwiftUI
import AppIntents

struct WayEntry: TimelineEntry {
    let date: Date
    let snap: WaySnapshotData
}

let wayPlaceholder = WaySnapshotData(
    journeyID: "abraham",
    journeyTitle: "Abraham's Road",
    waypointIndex: 0,
    place: "Ur of the Chaldees",
    reference: "Genesis 11:27-32",
    firstVerse: "Now these are the generations of Terah.",
    markerX: 0.85,
    markerY: 0.78,
    walkedInJourney: 0,
    journeyWaypoints: 10,
    milesWalked: 0,
    walkedToday: false,
    streak: 0
)

struct WayProvider: TimelineProvider {
    func placeholder(in context: Context) -> WayEntry {
        WayEntry(date: Date(), snap: wayPlaceholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WayEntry) -> Void) {
        completion(WayEntry(date: Date(), snap: WaySnapshotData.load() ?? wayPlaceholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WayEntry>) -> Void) {
        let entry = WayEntry(date: Date(), snap: WaySnapshotData.load() ?? wayPlaceholder)
        let next = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 2), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600 * 6)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct WalkStretchIntent: AppIntent {
    static var title: LocalizedStringResource = "Walk this stretch"
    static var description = IntentDescription("Marks the current Wayfarer's Word waypoint as walked.")

    @Parameter(title: "Token")
    var token: String

    init() {}
    init(token: String) { self.token = token }

    func perform() async throws -> some IntentResult {
        WayQueue.push(token)
        if var snap = WaySnapshotData.load() {
            snap = WaySnapshotData(journeyID: snap.journeyID, journeyTitle: snap.journeyTitle,
                                   waypointIndex: snap.waypointIndex, place: snap.place,
                                   reference: snap.reference, firstVerse: snap.firstVerse,
                                   markerX: snap.markerX, markerY: snap.markerY,
                                   walkedInJourney: snap.walkedInJourney + 1,
                                   journeyWaypoints: snap.journeyWaypoints,
                                   milesWalked: snap.milesWalked, walkedToday: true,
                                   streak: max(1, snap.streak))
            snap.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct RoadWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WayShared.roadKind, provider: WayProvider()) { entry in
            RoadWidgetView(entry: entry)
                .containerBackground(for: .widget) { WayWidgetPaper() }
        }
        .configurationDisplayName("On the Road")
        .description("Your caravan's place on the map and the next reading.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct MilesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WayShared.milesKind, provider: WayProvider()) { entry in
            MilesWidgetView(entry: entry)
                .containerBackground(for: .widget) { WayWidgetPaper() }
        }
        .configurationDisplayName("Miles Walked")
        .description("Your miles across all eight journeys.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

@main
struct WayfarerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoadWidget()
        MilesWidget()
    }
}
