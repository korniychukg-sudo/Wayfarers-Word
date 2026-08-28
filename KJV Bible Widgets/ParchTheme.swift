import SwiftUI

enum Parch {
    static let paper = Color(red: 0.965, green: 0.949, blue: 0.910)
    static let paperDeep = Color(red: 0.902, green: 0.882, blue: 0.823)
    static let card = Color(red: 0.992, green: 0.984, blue: 0.957)
    static let ink = Color(red: 0.070, green: 0.094, blue: 0.102)
    static let inkSoft = Color(red: 0.070, green: 0.094, blue: 0.102).opacity(0.64)
    static let inkFaint = Color(red: 0.070, green: 0.094, blue: 0.102).opacity(0.25)
    static let gold = Color(red: 0.680, green: 0.493, blue: 0.235)
    static let goldBright = Color(red: 0.906, green: 0.741, blue: 0.435)
    static let road = Color(red: 0.474, green: 0.253, blue: 0.180)
    static let water = Color(red: 0.157, green: 0.290, blue: 0.322)
    static let night = Color(red: 0.039, green: 0.071, blue: 0.078)
    static let nightRaised = Color(red: 0.071, green: 0.112, blue: 0.120)
    static let sage = Color(red: 0.343, green: 0.439, blue: 0.384)
}

extension Font {
    static func parchTitle(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    static func parchSerif(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static func parchItalic(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif).italic() }
    static func waySans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }
}

struct ParchBackground: View {
    var body: some View {
        ZStack {
            Parch.paper
            LinearGradient(colors: [Color.white.opacity(0.82), Parch.paper, Parch.paperDeep.opacity(0.52)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Parch.goldBright.opacity(0.12), .clear], center: .topTrailing, startRadius: 0, endRadius: 340)
        }
        .ignoresSafeArea()
    }
}

struct WaySectionTitle: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.waySans(11, weight: .bold))
                .kerning(1.7)
                .foregroundStyle(Parch.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(title)
                .font(.parchTitle(30))
                .foregroundStyle(Parch.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

struct WayPill: View {
    let icon: String
    let text: String
    var dark = false
    var body: some View {
        Label(text, systemImage: icon)
            .font(.waySans(11, weight: .semibold))
            .foregroundStyle(dark ? Color.white.opacity(0.88) : Parch.inkSoft)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

struct WayCardModifier: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(Parch.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.9), lineWidth: 1))
            .shadow(color: Parch.ink.opacity(0.09), radius: 18, y: 9)
    }
}

extension View {
    func wayCard(radius: CGFloat = 22) -> some View { modifier(WayCardModifier(radius: radius)) }
    func wayResponsiveColumn(maxWidth: CGFloat, inset: CGFloat = 18) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, inset)
            .frame(maxWidth: .infinity)
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
            case "camel":
                var sil = Path()
                sil.move(to: CGPoint(x: w * 0.1, y: h * 0.72))
                sil.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.46), control: CGPoint(x: w * 0.08, y: h * 0.54))
                sil.addQuadCurve(to: CGPoint(x: w * 0.44, y: h * 0.42), control: CGPoint(x: w * 0.3, y: h * 0.34))
                sil.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.44), control: CGPoint(x: w * 0.52, y: h * 0.3))
                sil.addLine(to: CGPoint(x: w * 0.66, y: h * 0.22))
                sil.addLine(to: CGPoint(x: w * 0.76, y: h * 0.18))
                sil.addLine(to: CGPoint(x: w * 0.72, y: h * 0.3))
                sil.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
                sil.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.72), control: CGPoint(x: w * 0.7, y: h * 0.64))
                sil.addLine(to: CGPoint(x: w * 0.6, y: h * 0.72))
                sil.addLine(to: CGPoint(x: w * 0.6, y: h * 0.56))
                sil.addLine(to: CGPoint(x: w * 0.3, y: h * 0.56))
                sil.addLine(to: CGPoint(x: w * 0.3, y: h * 0.72))
                sil.addLine(to: CGPoint(x: w * 0.24, y: h * 0.72))
                sil.addLine(to: CGPoint(x: w * 0.22, y: h * 0.56))
                sil.addLine(to: CGPoint(x: w * 0.14, y: h * 0.72))
                sil.closeSubpath()
                ctx.fill(sil, with: .color(color))
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

    static func hero(_ journey: String) -> UIImage? {
        let asset: String
        let ext: String
        switch journey {
        case "abraham": asset = "hero_abraham"; ext = "png"
        case "exodus": asset = "hero_exodus"; ext = "png"
        case "wilderness": asset = "hero_wilderness"; ext = "jpg"
        case "conquest": asset = "hero_conquest"; ext = "png"
        case "david": asset = "hero_david"; ext = "jpg"
        case "exile": asset = "hero_exile"; ext = "jpg"
        case "galilee": asset = "hero_galilee"; ext = "jpg"
        case "paul": asset = "hero_paul"; ext = "png"
        default: return nil
        }
        return cached("Maps/\(asset).\(ext)", asset, "Maps", ext: ext)
    }

    private static func cached(_ key: String, _ name: String, _ dir: String, ext: String = "jpg") -> UIImage? {
        if let c = mapCache.object(forKey: key as NSString) { return c }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir),
              let ui = UIImage(contentsOfFile: url.path) else { return nil }
        mapCache.setObject(ui, forKey: key as NSString)
        return ui
    }
}

struct JourneyMapView: View {
    let journey: WWJourney
    let walkedCount: Int

    private func routePath(points: [CGPoint], upTo lastIndex: Int, width: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1, lastIndex >= 1 else { return path }
        path.move(to: points[0])
        var bowSign: CGFloat = 1
        for j in 1..<points.count {
            let prev = points[j - 1]
            let cur = points[j]
            let dx = cur.x - prev.x
            let dy = cur.y - prev.y
            let segLen = max(sqrt(dx * dx + dy * dy), 1)
            let amp = min(segLen * 0.22, width * 0.03) * bowSign
            let ctrl = CGPoint(x: (prev.x + cur.x) / 2 - dy / segLen * amp, y: (prev.y + cur.y) / 2 + dx / segLen * amp)
            if j <= lastIndex {
                path.addQuadCurve(to: cur, control: ctrl)
            }
            bowSign = -bowSign
        }
        return path
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let ui = WayArt.map(journey.id) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                let pts = journey.waypoints.map { CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height) }
                if !pts.isEmpty {
                    let lastIndex = min(max(walkedCount - 1, 0), pts.count - 1)
                    if lastIndex >= 1 {
                        let walkedPath = routePath(points: pts, upTo: lastIndex, width: geo.size.width)
                        walkedPath
                            .stroke(Color(red: 0.30, green: 0.18, blue: 0.06).opacity(0.45),
                                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
                        walkedPath
                            .stroke(LinearGradient(colors: [Parch.goldBright, Parch.gold], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
                        walkedPath
                            .stroke(Color(red: 0.99, green: 0.9, blue: 0.6).opacity(0.9),
                                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                    }
                    let m = pts[lastIndex]
                    Circle()
                        .fill(Parch.goldBright.opacity(0.28))
                        .frame(width: 30, height: 30)
                        .position(m)
                    WayIcon(kind: "camel", size: 24, color: Parch.ink)
                        .shadow(color: Parch.paper.opacity(0.9), radius: 2)
                        .position(x: m.x, y: m.y - 4)
                }
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Parch.gold.opacity(0.55), lineWidth: 1.3))
    }
}
