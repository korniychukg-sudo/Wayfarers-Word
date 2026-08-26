import Foundation
import SwiftUI
import WidgetKit

struct WayBadge: Identifiable {
    let id: String
    let title: String
    let detail: String
}

struct WaySave: Codable {
    var walked: [String] = []
    var activeJourney: String = "abraham"
    var lastWalkStamp: Double? = nil
    var streak: Int = 0
    var bestStreak: Int = 0
    var quizBest: Int = 0
    var onboarded: Bool = false
    var plusUnlocked: Bool = false
    var walkDates: [Double] = []
    var fieldNotes: [String: String]? = nil
}

final class WayStore: ObservableObject {
    static let shared = WayStore()
    private static let saveKey = "ww.save.v1"

    @Published private(set) var walked: Set<String> = []
    @Published var activeJourney: String = "abraham"
    @Published private(set) var streak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published var quizBest: Int = 0
    @Published var onboarded: Bool = false
    @Published var plusUnlocked: Bool = false
    @Published var celebrateJourney: WWJourney? = nil
    @Published private(set) var fieldNotes: [String: String] = [:]
    private var lastWalkStamp: Date? = nil
    private var walkDates: [Date] = []

    let content = WayContent.shared

    private init() {
        load()
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-skipOnboarding") { onboarded = true }
        if ProcessInfo.processInfo.arguments.contains("-showOnboarding") { onboarded = false }
#endif
    }

    func token(_ journey: String, _ index: Int) -> String { "\(journey):\(index)" }

    func isWalked(_ journey: String, _ index: Int) -> Bool { walked.contains(token(journey, index)) }

    func walkedCount(_ journey: String) -> Int {
        guard let j = content.byID[journey] else { return 0 }
        return (0..<j.waypoints.count).filter { isWalked(journey, $0) }.count
    }

    func nextIndex(_ journey: String) -> Int? {
        guard let j = content.byID[journey] else { return nil }
        for k in 0..<j.waypoints.count where !isWalked(journey, k) { return k }
        return nil
    }

    func journeyDone(_ journey: String) -> Bool { nextIndex(journey) == nil }

    func isUnlocked(_ journey: String) -> Bool {
        plusUnlocked || journey == "abraham"
    }

    var milesWalked: Int {
        var total = 0
        for j in content.journeys {
            for (k, w) in j.waypoints.enumerated() where isWalked(j.journey, k) {
                total += w.miles
            }
        }
        return total
    }

    var totalMiles: Int { content.journeys.reduce(0) { $0 + $1.totalMiles } }

    var walkedToday: Bool {
        guard let stamp = lastWalkStamp else { return false }
        return Calendar.current.isDateInToday(stamp)
    }

    var currentWaypoint: (WWJourney, WWWaypoint, Int)? {
        guard let j = content.byID[activeJourney] else { return nil }
        if let k = nextIndex(activeJourney) {
            return (j, j.waypoints[k], k)
        }
        return (j, j.waypoints[j.waypoints.count - 1], j.waypoints.count - 1)
    }

    func markWalked(_ journey: String, _ index: Int) {
        let t = token(journey, index)
        guard !walked.contains(t), isUnlocked(journey) else { return }
        walked.insert(t)
        let cal = Calendar.current
        let now = Date()
        if let stamp = lastWalkStamp {
            if cal.isDateInToday(stamp) {
            } else if let yd = cal.date(byAdding: .day, value: -1, to: now), cal.isDate(stamp, inSameDayAs: yd) {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }
        bestStreak = max(bestStreak, streak)
        lastWalkStamp = now
        let today = cal.startOfDay(for: now)
        if !walkDates.contains(today) {
            walkDates.append(today)
            if walkDates.count > 80 { walkDates.removeFirst(walkDates.count - 80) }
        }
        if journeyDone(journey), let j = content.byID[journey] {
            celebrateJourney = j
        }
        persist()
    }

    func fieldNote(for t: String) -> String? { fieldNotes[t] }

    func setFieldNote(_ t: String, _ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            fieldNotes.removeValue(forKey: t)
        } else {
            fieldNotes[t] = trimmed
        }
        persist()
    }

    var notedWaypoints: [(WWJourney, WWWaypoint, Int, String)] {
        var out: [(WWJourney, WWWaypoint, Int, String)] = []
        for j in content.journeys {
            for (k, w) in j.waypoints.enumerated() {
                if let text = fieldNotes[token(j.journey, k)] {
                    out.append((j, w, k, text))
                }
            }
        }
        return out
    }

    func drainWidgetQueue() {
        for t in WayQueue.drain() {
            let parts = t.split(separator: ":")
            if parts.count == 2, let idx = Int(parts[1]) {
                markWalked(String(parts[0]), idx)
            }
        }
        publishSnapshot()
    }

    var earnedBadges: Set<String> {
        var earned = Set<String>()
        if !walked.isEmpty { earned.insert("first") }
        for j in content.journeys where journeyDone(j.journey) { earned.insert("j.\(j.journey)") }
        let done = content.journeys.filter { journeyDone($0.journey) }.count
        if done >= 1 { earned.insert("onedone") }
        if done >= 3 { earned.insert("threedone") }
        if done >= 8 { earned.insert("alldone") }
        let m = milesWalked
        if m >= 100 { earned.insert("m100") }
        if m >= 1000 { earned.insert("m1000") }
        if m >= 3000 { earned.insert("m3000") }
        if bestStreak >= 7 { earned.insert("streak7") }
        return earned
    }

    static let badges: [WayBadge] = [
        WayBadge(id: "first", title: "First Step", detail: "Walk your first waypoint"),
        WayBadge(id: "onedone", title: "Road's End", detail: "Finish a whole journey"),
        WayBadge(id: "threedone", title: "Seasoned Walker", detail: "Finish three journeys"),
        WayBadge(id: "alldone", title: "Wayfarer", detail: "Finish all eight journeys"),
        WayBadge(id: "m100", title: "Hundred Miles", detail: "Walk 100 miles of road"),
        WayBadge(id: "m1000", title: "Thousand Miles", detail: "Walk 1,000 miles of road"),
        WayBadge(id: "m3000", title: "The Long Haul", detail: "Walk 3,000 miles of road"),
        WayBadge(id: "streak7", title: "Steady Feet", detail: "A 7-day walking streak"),
    ] + WayContent.shared.journeys.map { j in
        WayBadge(id: "j.\(j.journey)", title: j.title, detail: "Finish \(j.title)")
    }

    func heat(weeksBack: Int = 5) -> [[Bool]] {
        let cal = Calendar.current
        var grid: [[Bool]] = []
        let today = cal.startOfDay(for: Date())
        let dates = Set(walkDates.map { cal.startOfDay(for: $0) })
        for w in (0..<weeksBack).reversed() {
            var row: [Bool] = []
            for d in (0..<7).reversed() {
                if let day = cal.date(byAdding: .day, value: -(w * 7 + d), to: today) {
                    row.append(dates.contains(cal.startOfDay(for: day)))
                } else {
                    row.append(false)
                }
            }
            grid.append(row)
        }
        return grid
    }

    func setPlus(_ value: Bool) {
        guard plusUnlocked != value else { return }
        plusUnlocked = value
        persist()
    }

    func completeOnboarding() {
        onboarded = true
        persist()
    }

    func resetProgress() {
        walked = []
        fieldNotes = [:]
        streak = 0
        bestStreak = 0
        quizBest = 0
        lastWalkStamp = nil
        walkDates = []
        activeJourney = "abraham"
        persist()
    }

    func persist() {
        var save = WaySave()
        save.walked = Array(walked)
        save.activeJourney = activeJourney
        save.lastWalkStamp = lastWalkStamp?.timeIntervalSince1970
        save.streak = streak
        save.bestStreak = bestStreak
        save.quizBest = quizBest
        save.onboarded = onboarded
        save.plusUnlocked = plusUnlocked
        save.walkDates = walkDates.map { $0.timeIntervalSince1970 }
        save.fieldNotes = fieldNotes
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: WayStore.saveKey)
        }
        publishSnapshot()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: WayStore.saveKey),
              let save = try? JSONDecoder().decode(WaySave.self, from: data) else { return }
        walked = Set(save.walked)
        activeJourney = save.activeJourney
        streak = save.streak
        bestStreak = save.bestStreak
        quizBest = save.quizBest
        onboarded = save.onboarded
        plusUnlocked = save.plusUnlocked
        walkDates = save.walkDates.map { Date(timeIntervalSince1970: $0) }
        fieldNotes = save.fieldNotes ?? [:]
        if let stamp = save.lastWalkStamp {
            lastWalkStamp = Date(timeIntervalSince1970: stamp)
        }
        let cal = Calendar.current
        if let stamp = lastWalkStamp,
           !cal.isDateInToday(stamp),
           !(cal.date(byAdding: .day, value: -1, to: Date()).map { cal.isDate(stamp, inSameDayAs: $0) } ?? false) {
            streak = 0
        }
    }

    func publishSnapshot() {
        guard let (journey, waypoint, index) = currentWaypoint else { return }
        let snap = WaySnapshotData(
            journeyID: journey.journey,
            journeyTitle: journey.title,
            waypointIndex: index,
            place: waypoint.place,
            reference: waypoint.reference,
            firstVerse: waypoint.verses.first ?? "",
            markerX: waypoint.x,
            markerY: waypoint.y,
            walkedInJourney: walkedCount(journey.journey),
            journeyWaypoints: journey.waypoints.count,
            milesWalked: milesWalked,
            walkedToday: walkedToday,
            streak: streak
        )
        snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
