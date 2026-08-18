import SwiftUI
import WidgetKit

enum WParch {
    static let paper = Color(red: 0.929, green: 0.888, blue: 0.784)
    static let ink = Color(red: 0.235, green: 0.196, blue: 0.137)
    static let inkSoft = Color(red: 0.235, green: 0.196, blue: 0.137).opacity(0.6)
    static let gold = Color(red: 0.663, green: 0.478, blue: 0.149)
    static let goldBright = Color(red: 0.831, green: 0.647, blue: 0.243)
}

struct WayWidgetPaper: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.957, green: 0.929, blue: 0.859), WParch.paper, Color(red: 0.878, green: 0.820, blue: 0.694)],
                       startPoint: .top, endPoint: .bottom)
    }
}

func widgetMap(_ journey: String) -> UIImage? {
    guard let url = Bundle.main.url(forResource: "wmap_\(journey)", withExtension: "jpg", subdirectory: "MapsSmall") else { return nil }
    return UIImage(contentsOfFile: url.path)
}

struct MapMarkerView: View {
    let journey: String
    let x: Double
    let y: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let ui = widgetMap(journey) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                Circle()
                    .fill(WParch.gold.opacity(0.3))
                    .frame(width: 18, height: 18)
                    .position(x: x * geo.size.width, y: y * geo.size.height)
                Circle()
                    .fill(WParch.goldBright)
                    .overlay(Circle().stroke(WParch.ink, lineWidth: 1.4))
                    .frame(width: 11, height: 11)
                    .position(x: x * geo.size.width, y: y * geo.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(WParch.gold.opacity(0.5), lineWidth: 1))
    }
}

struct RoadWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WayEntry

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .accessoryRectangular: rect
        default: inline
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 5) {
            MapMarkerView(journey: entry.snap.journeyID, x: entry.snap.markerX, y: entry.snap.markerY)
                .frame(maxHeight: .infinity)
            Text(entry.snap.place)
                .font(.custom("Georgia-Bold", size: 12.5))
                .foregroundColor(WParch.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("Stop \(entry.snap.waypointIndex + 1) of \(entry.snap.journeyWaypoints)")
                .font(.custom("Georgia", size: 10))
                .foregroundColor(WParch.inkSoft)
        }
    }

    private var medium: some View {
        HStack(spacing: 12) {
            MapMarkerView(journey: entry.snap.journeyID, x: entry.snap.markerX, y: entry.snap.markerY)
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.snap.journeyTitle.uppercased())
                    .font(.custom("Georgia-Bold", size: 9))
                    .foregroundColor(WParch.gold)
                    .kerning(1.0)
                    .lineLimit(1)
                Text(entry.snap.place)
                    .font(.custom("Georgia-Bold", size: 15))
                    .foregroundColor(WParch.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(entry.snap.reference)
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(WParch.inkSoft)
                    .lineLimit(1)
                Spacer(minLength: 2)
                if entry.snap.walkedToday {
                    HStack(spacing: 5) {
                        Circle().fill(WParch.gold).frame(width: 6, height: 6)
                        Text("Walked today")
                            .font(.custom("Georgia", size: 11))
                            .foregroundColor(WParch.gold)
                    }
                } else {
                    Button(intent: WalkStretchIntent(token: "\(entry.snap.journeyID):\(entry.snap.waypointIndex)")) {
                        Text("Walk this stretch")
                            .font(.custom("Georgia-Bold", size: 11.5))
                            .foregroundColor(WParch.paper)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(WParch.gold))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var rect: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.snap.journeyTitle)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .lineLimit(1)
            Text(entry.snap.place)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .lineLimit(1)
            Text("\(entry.snap.reference) · stop \(entry.snap.waypointIndex + 1)/\(entry.snap.journeyWaypoints)")
                .font(.system(size: 10.5, design: .serif))
                .opacity(0.75)
                .lineLimit(1)
        }
    }

    private var inline: some View {
        Text("\(entry.snap.place) · \(entry.snap.reference)")
    }
}

struct MilesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WayEntry

    var body: some View {
        if family == .accessoryCircular {
            Gauge(value: Double(entry.snap.milesWalked), in: 0...7780) {
                Text("mi")
            } currentValueLabel: {
                Text("\(entry.snap.milesWalked)")
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .stroke(WParch.ink.opacity(0.15), lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.snap.milesWalked) / 7780.0)
                        .stroke(WParch.gold, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(entry.snap.milesWalked)")
                            .font(.custom("Georgia-Bold", size: 21))
                            .foregroundColor(WParch.ink)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        Text("of 7,780 mi")
                            .font(.custom("Georgia", size: 9))
                            .foregroundColor(WParch.inkSoft)
                    }
                    .padding(.horizontal, 10)
                }
                .frame(width: 84, height: 84)
                Text(entry.snap.streak > 0 ? "\(entry.snap.streak)-day streak" : "The road waits")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(WParch.gold)
            }
        }
    }
}
