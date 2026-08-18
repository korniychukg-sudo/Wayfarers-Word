import SwiftUI

enum Parch {
    static let paper = Color(red: 0.929, green: 0.888, blue: 0.784)
    static let paperDeep = Color(red: 0.878, green: 0.820, blue: 0.694)
    static let card = Color(red: 0.957, green: 0.929, blue: 0.859)
    static let ink = Color(red: 0.235, green: 0.196, blue: 0.137)
    static let inkSoft = Color(red: 0.235, green: 0.196, blue: 0.137).opacity(0.6)
    static let inkFaint = Color(red: 0.235, green: 0.196, blue: 0.137).opacity(0.32)
    static let gold = Color(red: 0.663, green: 0.478, blue: 0.149)
    static let goldBright = Color(red: 0.831, green: 0.647, blue: 0.243)
    static let road = Color(red: 0.416, green: 0.208, blue: 0.169)
    static let water = Color(red: 0.318, green: 0.412, blue: 0.471)
}

extension Font {
    static func parchTitle(_ size: CGFloat) -> Font { .custom("Georgia-Bold", size: size) }
    static func parchSerif(_ size: CGFloat) -> Font { .custom("Georgia", size: size) }
    static func parchItalic(_ size: CGFloat) -> Font { .custom("Georgia-Italic", size: size) }
}

struct ParchBackground: View {
    var body: some View {
        ZStack {
            Parch.paper
            LinearGradient(colors: [Parch.card.opacity(0.9), Parch.paper, Parch.paperDeep.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
            Canvas { ctx, size in
                var seed: UInt64 = 4411
                func rnd() -> Double {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return Double((seed >> 33) % 10000) / 10000.0
                }
                for _ in 0..<120 {
                    let x = rnd() * size.width
                    let y = rnd() * size.height
                    let len = 4 + rnd() * 10
                    let a = rnd() * .pi
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x + cos(a) * len, y: y + sin(a) * len))
                    ctx.stroke(p, with: .color(Parch.ink.opacity(0.04 + rnd() * 0.04)), lineWidth: 0.8)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct RoadRule: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Parch.gold.opacity(0.7)).frame(height: 1)
            Circle().fill(Parch.goldBright).frame(width: 5, height: 5)
            Rectangle().fill(Parch.gold.opacity(0.7)).frame(height: 1)
        }
    }
}

struct WayIcon: View {
    let kind: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height
            let line = StrokeStyle(lineWidth: max(1.6, w * 0.07), lineCap: .round, lineJoin: .round)
            switch kind {
            case "boot":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.3, y: h * 0.14))
                p.addLine(to: CGPoint(x: w * 0.56, y: h * 0.14))
                p.addLine(to: CGPoint(x: w * 0.58, y: h * 0.52))
                p.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.72), control: CGPoint(x: w * 0.82, y: h * 0.54))
                p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.84))
                p.addLine(to: CGPoint(x: w * 0.16, y: h * 0.84))
                p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.14))
                ctx.stroke(p, with: .color(color), style: line)
                var lace = Path()
                lace.move(to: CGPoint(x: w * 0.32, y: h * 0.3))
                lace.addLine(to: CGPoint(x: w * 0.54, y: h * 0.32))
                lace.move(to: CGPoint(x: w * 0.31, y: h * 0.42))
                lace.addLine(to: CGPoint(x: w * 0.55, y: h * 0.44))
                ctx.stroke(lace, with: .color(color), style: StrokeStyle(lineWidth: max(1.2, w * 0.05), lineCap: .round))
            case "compass":
                let c = CGPoint(x: w / 2, y: h / 2)
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)), with: .color(color), style: line)
                var n = Path()
                n.move(to: CGPoint(x: c.x - w * 0.1, y: c.y + h * 0.12))
                n.addLine(to: CGPoint(x: c.x, y: c.y - h * 0.26))
                n.addLine(to: CGPoint(x: c.x + w * 0.1, y: c.y + h * 0.12))
                n.addLine(to: CGPoint(x: c.x, y: c.y + h * 0.26))
                n.closeSubpath()
                ctx.fill(n, with: .color(color))
            case "map":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.14, y: h * 0.22))
                p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.14))
                p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.22))
                p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.14))
                p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.78))
                p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.86))
                p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.78))
                p.addLine(to: CGPoint(x: w * 0.14, y: h * 0.86))
                p.closeSubpath()
                ctx.stroke(p, with: .color(color), style: line)
                var dash = Path()
                dash.move(to: CGPoint(x: w * 0.26, y: h * 0.62))
                dash.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.4), control: CGPoint(x: w * 0.5, y: h * 0.7))
                ctx.stroke(dash, with: .color(color), style: StrokeStyle(lineWidth: max(1.2, w * 0.05), lineCap: .round, dash: [3, 3]))
            case "book":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
                p.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.18), control: CGPoint(x: w * 0.3, y: h * 0.1))
                p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.74))
                p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.82), control: CGPoint(x: w * 0.32, y: h * 0.72))
                p.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.74), control: CGPoint(x: w * 0.68, y: h * 0.72))
                p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.18))
                p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.2), control: CGPoint(x: w * 0.7, y: h * 0.1))
                p.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.82))
                ctx.stroke(p, with: .color(color), style: line)
            case "lamp":
                var bowl = Path()
                bowl.move(to: CGPoint(x: w * 0.2, y: h * 0.5))
                bowl.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.76))
                bowl.closeSubpath()
                ctx.stroke(bowl, with: .color(color), style: line)
                var fl = Path()
                fl.move(to: CGPoint(x: w * 0.5, y: h * 0.44))
                fl.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.14), control: CGPoint(x: w * 0.32, y: h * 0.28))
                fl.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.44), control: CGPoint(x: w * 0.66, y: h * 0.3))
                ctx.stroke(fl, with: .color(color), style: line)
                var foot = Path()
                foot.move(to: CGPoint(x: w * 0.36, y: h * 0.88))
                foot.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.88), control: CGPoint(x: w * 0.5, y: h * 0.74))
                ctx.stroke(foot, with: .color(color), style: line)
            case "lock":
                let r = CGRect(x: w * 0.24, y: h * 0.44, width: w * 0.52, height: h * 0.4)
                ctx.stroke(Path(roundedRect: r, cornerRadius: w * 0.07), with: .color(color), style: line)
                var arc = Path()
                arc.addArc(center: CGPoint(x: w * 0.5, y: h * 0.44), radius: w * 0.17,
                           startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                ctx.stroke(arc, with: .color(color), style: line)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.58, width: w * 0.08, height: w * 0.08)), with: .color(color))
            case "check":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.2, y: h * 0.54))
                p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.76))
                p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.28))
                ctx.stroke(p, with: .color(color), style: line)
            case "cross":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.26, y: h * 0.26))
                p.addLine(to: CGPoint(x: w * 0.74, y: h * 0.74))
                p.move(to: CGPoint(x: w * 0.74, y: h * 0.26))
                p.addLine(to: CGPoint(x: w * 0.26, y: h * 0.74))
                ctx.stroke(p, with: .color(color), style: line)
            case "chevron":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.36, y: h * 0.2))
                p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.5))
                p.addLine(to: CGPoint(x: w * 0.36, y: h * 0.8))
                ctx.stroke(p, with: .color(color), style: line)
            case "star":
                let c = CGPoint(x: w / 2, y: h / 2)
                var p = Path()
                for k in 0..<8 {
                    let a = Double(k) * .pi / 4 - .pi / 2
                    let rr = k % 2 == 0 ? w * 0.42 : w * 0.16
                    let pt = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
                    if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                ctx.fill(p, with: .color(color))
            case "restore":
                var arc = Path()
                arc.addArc(center: CGPoint(x: w / 2, y: h / 2), radius: w * 0.3,
                           startAngle: .degrees(30), endAngle: .degrees(300), clockwise: false)
                ctx.stroke(arc, with: .color(color), style: line)
                var tip = Path()
                tip.move(to: CGPoint(x: w * 0.74, y: h * 0.28))
                tip.addLine(to: CGPoint(x: w * 0.8, y: h * 0.46))
                tip.addLine(to: CGPoint(x: w * 0.62, y: h * 0.44))
                tip.closeSubpath()
                ctx.fill(tip, with: .color(color))
            case "tent":
                var p = Path()
                p.move(to: CGPoint(x: w * 0.12, y: h * 0.78))
                p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.2))
                p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.78))
                p.closeSubpath()
                ctx.stroke(p, with: .color(color), style: line)
                var door = Path()
                door.move(to: CGPoint(x: w * 0.4, y: h * 0.78))
                door.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                door.addLine(to: CGPoint(x: w * 0.6, y: h * 0.78))
                ctx.stroke(door, with: .color(color), style: StrokeStyle(lineWidth: max(1.2, w * 0.05), lineCap: .round))
            default:
                break
            }
        }
        .frame(width: size, height: size)
    }
}

enum WayArt {
    static let mapCache = NSCache<NSString, UIImage>()

    static func map(_ journey: String) -> UIImage? {
        cached("Maps/map_\(journey)", "map_\(journey)", "Maps")
    }

    static func vignette(_ journey: String, _ index: Int) -> UIImage? {
        cached("Vignettes/v_\(journey)_\(index)", "v_\(journey)_\(index)", "Vignettes")
    }

    private static func cached(_ key: String, _ name: String, _ dir: String) -> UIImage? {
        if let c = mapCache.object(forKey: key as NSString) { return c }
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: dir),
              let ui = UIImage(contentsOfFile: url.path) else { return nil }
        mapCache.setObject(ui, forKey: key as NSString)
        return ui
    }
}

struct JourneyMapView: View {
    let journey: WWJourney
    let walkedCount: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let ui = WayArt.map(journey.id) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                Canvas { ctx, size in
                    let pts = journey.waypoints.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                    guard !pts.isEmpty else { return }
                    if walkedCount > 1 {
                        var walked = Path()
                        walked.move(to: pts[0])
                        for j in 1..<min(walkedCount, pts.count) {
                            walked.addLine(to: pts[j])
                        }
                        ctx.stroke(walked, with: .color(Parch.gold), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                    let markerIndex = min(max(walkedCount - 1, 0), pts.count - 1)
                    let m = pts[markerIndex]
                    ctx.fill(Path(ellipseIn: CGRect(x: m.x - 11, y: m.y - 11, width: 22, height: 22)), with: .color(Parch.gold.opacity(0.3)))
                    ctx.fill(Path(ellipseIn: CGRect(x: m.x - 6.5, y: m.y - 6.5, width: 13, height: 13)), with: .color(Parch.goldBright))
                    ctx.stroke(Path(ellipseIn: CGRect(x: m.x - 6.5, y: m.y - 6.5, width: 13, height: 13)), with: .color(Parch.ink), lineWidth: 1.6)
                }
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Parch.gold.opacity(0.55), lineWidth: 1.3))
    }
}
