import Foundation

enum WayLinks {
    static let support = URL(string: "https://www.termsfeed.com/live/1ca6ac34-ad04-481a-90ad-a31ab4af3740")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

struct WWWaypoint: Codable, Identifiable {
    let place: String
    let placeNote: String
    let book: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let narration: String
    let miles: Int
    let x: Double
    let y: Double
    let terrain: String
    let verses: [String]

    var id: String { place }
    var reference: String {
        verseStart == verseEnd ? "\(book) \(chapter):\(verseStart)" : "\(book) \(chapter):\(verseStart)-\(verseEnd)"
    }
}

struct WWJourney: Codable, Identifiable {
    let journey: String
    let title: String
    let subtitle: String
    let essay: String
    let waypoints: [WWWaypoint]

    var id: String { journey }
    var totalMiles: Int { waypoints.reduce(0) { $0 + $1.miles } }
}

struct WWContent: Codable {
    let journeys: [WWJourney]
}

final class WayContent {
    static let shared = WayContent()
    let journeys: [WWJourney]
    let byID: [String: WWJourney]

    private init() {
        guard let url = Bundle.main.url(forResource: "journeys", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(WWContent.self, from: data) else {
            journeys = []; byID = [:]
            return
        }
        journeys = content.journeys
        byID = Dictionary(uniqueKeysWithValues: journeys.map { ($0.journey, $0) })
    }
}

struct WayTerm: Identifiable {
    let term: String
    let meaning: String
    var id: String { term }
}

enum WayGlossary {
    static let terms: [WayTerm] = [
        WayTerm(term: "Caravan", meaning: "A company traveling together with pack animals, the only safe way across long roads in the ancient Near East."),
        WayTerm(term: "Cubit", meaning: "The distance from elbow to fingertip, about eighteen inches; the everyday measure of the ancient world."),
        WayTerm(term: "A day's journey", meaning: "How the Bible measures roads: roughly fifteen to twenty-five miles on foot, less through hills."),
        WayTerm(term: "The King's Highway", meaning: "The old trade road east of the Jordan running from the Gulf north to Damascus; Israel asked Edom for passage along it."),
        WayTerm(term: "The Way of the Sea", meaning: "The coast road from Egypt north through Philistia and Megiddo toward Damascus, the busiest road in the region."),
        WayTerm(term: "Wadi", meaning: "A desert streambed, bone dry most of the year and a flash flood after rain; the Bible's brooks Zered and Arnon are wadis."),
        WayTerm(term: "Oasis", meaning: "A watered place in the desert, like Elim with its twelve wells and seventy palms. Roads bend toward water."),
        WayTerm(term: "Well", meaning: "A dug water source, life itself in the hill country; meetings at wells decide half the marriages in Genesis."),
        WayTerm(term: "Cistern", meaning: "A pit cut in rock to catch rainwater. A dry one made a handy prison for Joseph and Jeremiah."),
        WayTerm(term: "Tell", meaning: "A mound built up from generations of cities each raised on the ruins of the last; Jericho and Hazor stand on tells."),
        WayTerm(term: "Gate", meaning: "The strong point of a walled city and its courtroom; business and judgment happened in the gate, as at Ruth's Bethlehem."),
        WayTerm(term: "Threshing floor", meaning: "A flat open place where grain was beaten and winnowed; high, windy, and public — and twice a hinge of the story."),
        WayTerm(term: "Shekel", meaning: "A weight of silver before it was ever a coin, the price language of the whole Old Testament."),
        WayTerm(term: "Manna", meaning: "The bread that came with the dew through forty wilderness years; the name asks its own question, what is it?"),
        WayTerm(term: "Pillar of cloud", meaning: "The visible sign of God leading the camp, cloud by day and fire by night, moving when it was time to move."),
        WayTerm(term: "Ark of the Covenant", meaning: "The gold-covered chest that led the march and crossed the Jordan first; the sign that God walked the road too."),
        WayTerm(term: "Sojourner", meaning: "A resident foreigner living under a household's protection; the law repeats that Israel were sojourners once."),
        WayTerm(term: "Sea of Galilee", meaning: "A freshwater lake thirteen miles long, ringed by fishing towns and quick to sudden storms funneled down from the hills."),
        WayTerm(term: "Decapolis", meaning: "A league of ten Greek-speaking cities east of Galilee, pagan country to most Jews and part of Jesus' circuit anyway."),
        WayTerm(term: "Centurion", meaning: "A Roman officer over about a hundred soldiers; several of them meet the gospel with surprising faith."),
        WayTerm(term: "Synagogue", meaning: "The local assembly house for scripture and prayer, Paul's first stop in nearly every city on his map."),
        WayTerm(term: "Agora", meaning: "The Greek marketplace and public square; in Athens Paul argued in the agora daily with whoever would stand still."),
        WayTerm(term: "Euroclydon", meaning: "The violent northeaster of the eastern Mediterranean; the storm that drove Paul's grain ship fourteen days to Malta."),
        WayTerm(term: "Appian Way", meaning: "The paved Roman road Paul finally walked into Rome, met by believers who came out forty miles to meet him."),
    ]
}
