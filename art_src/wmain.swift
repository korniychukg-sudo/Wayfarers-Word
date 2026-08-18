import Foundation
import CoreGraphics
import ImageIO

struct WJWaypoint: Decodable {
    let place: String
    let book: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let miles: Int
    let x: Double
    let y: Double
    let terrain: String
}

struct WJourney: Decodable {
    let journey: String
    let title: String
    let subtitle: String
    let waypoints: [WJWaypoint]
}

struct WContent: Decodable {
    let journeys: [WJourney]
}

@main
struct WGenMain {
    static func main() {
        let args = CommandLine.arguments
        let contentPath = args[1]
        let outDir = URL(fileURLWithPath: args[2])
        try? FileManager.default.createDirectory(at: outDir.appendingPathComponent("Maps"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: outDir.appendingPathComponent("MapsSmall"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: outDir.appendingPathComponent("Vignettes"), withIntermediateDirectories: true)
        
        let content = try! JSONDecoder().decode(WContent.self, from: Data(contentsOf: URL(fileURLWithPath: contentPath)))
        
        for (ji, journey) in content.journeys.enumerated() {
            var rng = WRNG(seed: UInt64(ji) &* 7919 &+ 33)
            let ctx = wCtx(Int(MW * 1.5), Int(MH * 1.5))
            ctx.scaleBy(x: 1.5, y: 1.5)
            wPaperBase(ctx, MW, MH, &rng)
            let feats = journeyFeatures[journey.journey] ?? MapFeatures()
            for dunes in feats.dunes { drawDunes(ctx, dunes, count: 26, &rng) }
            for water in feats.water { drawWater(ctx, blobPath(water, &rng), &rng) }
            for river in feats.rivers { drawRiver(ctx, river, &rng) }
            for mts in feats.mountains { drawMountains(ctx, mts, count: 16, &rng) }
            drawPalms(ctx, at: feats.palms, &rng)
        
            let route = CGMutablePath()
            let pts = journey.waypoints.map { CGPoint(x: $0.x * MW, y: $0.y * MH) }
            route.move(to: pts[0])
            var bowSign = 1.0
            for j in 1..<pts.count {
                let prev = pts[j - 1]
                let cur = pts[j]
                let dx = cur.x - prev.x
                let dy = cur.y - prev.y
                let segLen = max(sqrt(dx * dx + dy * dy), 1)
                let amp = min(segLen * 0.22, MW * 0.03) * bowSign
                let ctrl = CGPoint(x: (prev.x + cur.x) / 2 - dy / segLen * amp, y: (prev.y + cur.y) / 2 + dx / segLen * amp)
                route.addQuadCurve(to: cur, control: ctrl)
                bowSign = -bowSign
            }
            wStroke(ctx, route, wc(0.30, 0.18, 0.06, 0.28), 6)
            wStroke(ctx, route, wSeal.copy(alpha: 0.85)!, 3.0, dash: [13, 9])
        
            for (k, p) in pts.enumerated() {
                let start = k == 0
                let end = k == pts.count - 1
                ctx.setFillColor(wPaper)
                ctx.fillEllipse(in: CGRect(x: p.x - 11, y: p.y - 11, width: 22, height: 22))
                ctx.setStrokeColor(start || end ? wGoldD : wInk)
                ctx.setLineWidth(2.4)
                ctx.strokeEllipse(in: CGRect(x: p.x - 11, y: p.y - 11, width: 22, height: 22))
                ctx.setFillColor(start || end ? wGoldM : wSeal)
                ctx.fillEllipse(in: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9))
                let labelY = p.y + (p.y > MH * 0.85 ? -30.0 : 30.0)
                mapText(ctx, journey.waypoints[k].place, at: CGPoint(x: p.x, y: labelY), size: 22, color: wInk)
            }
        
            for (label, lx, ly) in seaLabels[journey.journey] ?? [] {
                mapText(ctx, label, at: CGPoint(x: lx * MW, y: ly * MH), size: 24, color: wc(0.318, 0.412, 0.471), bold: false, italic: true)
            }
        
            compassRose(ctx, at: CGPoint(x: MW - 130, y: 140), r: 62, &rng)
        
            let cartW: Double = 460
            let cart = CGRect(x: 60, y: MH - 170, width: cartW, height: 110)
            ctx.setFillColor(wPaper.copy(alpha: 0.92)!)
            ctx.fill(cart)
            ctx.setStrokeColor(wInk)
            ctx.setLineWidth(2.2)
            ctx.stroke(cart)
            ctx.setStrokeColor(wGoldD)
            ctx.setLineWidth(1.2)
            ctx.stroke(cart.insetBy(dx: 6, dy: 6))
            mapText(ctx, journey.title, at: CGPoint(x: cart.midX, y: cart.minY + 42), size: 34, color: wInk)
            let totalMiles = journey.waypoints.reduce(0) { $0 + $1.miles }
            mapText(ctx, "about \(totalMiles) miles", at: CGPoint(x: cart.midX, y: cart.minY + 80), size: 20, color: wGoldD, bold: false, italic: true)
        
            let border = CGRect(x: 26, y: 26, width: MW - 52, height: MH - 52)
            ctx.setStrokeColor(wInk.copy(alpha: 0.8)!)
            ctx.setLineWidth(3.0)
            ctx.stroke(border)
            ctx.setStrokeColor(wGoldD)
            ctx.setLineWidth(1.4)
            ctx.stroke(border.insetBy(dx: 8, dy: 8))
        
            let url = outDir.appendingPathComponent("Maps/map_\(journey.journey).jpg")
            wWriteJPEG(ctx, url, 0.88)
        
            let img = ctx.makeImage()!
            let sctx = wCtx(700, 525)
            sctx.interpolationQuality = .high
            sctx.draw(img, in: CGRect(x: 0, y: 0, width: 700, height: 525))
            wWriteJPEG(sctx, outDir.appendingPathComponent("MapsSmall/wmap_\(journey.journey).jpg"), 0.8)
            print("map", journey.journey)
        
            for (k, wp) in journey.waypoints.enumerated() {
                var vr = WRNG(seed: UInt64(ji * 100 + k) &* 6271 &+ 5)
                let vctx = wCtx(1350, 1013)
                vctx.scaleBy(x: 1.5, y: 1.5)
                renderVignette(vctx, terrain: wp.terrain, rng: &vr)
                wWriteJPEG(vctx, outDir.appendingPathComponent("Vignettes/v_\(journey.journey)_\(k).jpg"), 0.88)
            }
            print("vignettes", journey.journey, journey.waypoints.count)
        }
        print("ALL DONE")
    }
}
