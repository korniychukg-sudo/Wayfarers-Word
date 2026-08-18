import Foundation

enum WayShared {
    static let groupID = "group.com.wayfarersword.app"
    static let snapshotKey = "ww.widget.snapshot"
    static let queueKey = "ww.widget.queue"
    static let roadKind = "WayfarerRoad"
    static let milesKind = "WayfarerMiles"
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
