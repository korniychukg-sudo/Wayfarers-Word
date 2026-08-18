import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct WRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
    mutating func d(_ lo: Double, _ hi: Double) -> Double {
        lo + (hi - lo) * (Double(next() % 100000) / 100000.0)
    }
    mutating func i(_ lo: Int, _ hi: Int) -> Int { lo + Int(next() % UInt64(hi - lo + 1)) }
    mutating func chance(_ p: Double) -> Bool { d(0, 1) < p }
}

func wc(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

let wPaper = wc(0.929, 0.888, 0.784)
let wPaperEdge = wc(0.855, 0.788, 0.647)
let wInk = wc(0.235, 0.196, 0.137)
let wInkSoft = wc(0.235, 0.196, 0.137, 0.55)
let wWater = wc(0.318, 0.412, 0.471)
let wGoldD = wc(0.62, 0.44, 0.13)
let wGoldM = wc(0.80, 0.62, 0.22)
let wGoldH = wc(0.95, 0.83, 0.45)
let wSeal = wc(0.416, 0.208, 0.169)

let MW: Double = 1600
let MH: Double = 1200

func wCtx(_ w: Int, _ h: Int) -> CGContext {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                      space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    c.translateBy(x: 0, y: Double(h))
    c.scaleBy(x: 1, y: -1)
    return c
}

func wWriteJPEG(_ ctx: CGContext, _ url: URL, _ q: Double) {
    let img = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: q] as CFDictionary)
    CGImageDestinationFinalize(dest)
}

func wStroke(_ ctx: CGContext, _ p: CGPath, _ col: CGColor, _ w: Double, dash: [CGFloat] = []) {
    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    if !dash.isEmpty { ctx.setLineDash(phase: 0, lengths: dash) }
    ctx.setStrokeColor(col)
    ctx.setLineWidth(w)
    ctx.addPath(p)
    ctx.strokePath()
    ctx.restoreGState()
}

func wFill(_ ctx: CGContext, _ p: CGPath, _ col: CGColor) {
    ctx.saveGState()
    ctx.addPath(p)
    ctx.setFillColor(col)
    ctx.fillPath()
    ctx.restoreGState()
}

func wHatch(_ ctx: CGContext, _ path: CGPath, angle: Double, gap: Double, col: CGColor, width: Double, _ rng: inout WRNG) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let r = path.boundingBox
    ctx.setStrokeColor(col)
    ctx.setLineWidth(width)
    let diag = sqrt(r.width * r.width + r.height * r.height)
    let n = Int(diag / gap) + 2
    let dirX = cos(angle); let dirY = sin(angle)
    let px = -dirY; let py = dirX
    for k in -n...n {
        let off = Double(k) * gap + rng.d(-1.2, 1.2)
        let cx = r.midX + px * off; let cy = r.midY + py * off
        ctx.move(to: CGPoint(x: cx - dirX * diag, y: cy - dirY * diag))
        ctx.addLine(to: CGPoint(x: cx + dirX * diag, y: cy + dirY * diag))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

func wPaperBase(_ ctx: CGContext, _ w: Double, _ h: Double, _ rng: inout WRNG) {
    ctx.setFillColor(wPaper)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let grad = CGGradient(colorsSpace: cs, colors: [wc(1, 0.98, 0.9, 0.5), wc(0.86, 0.78, 0.62, 0.0), wPaperEdge] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawRadialGradient(grad, startCenter: CGPoint(x: w / 2, y: h / 2), startRadius: 40,
                           endCenter: CGPoint(x: w / 2, y: h / 2), endRadius: max(w, h) * 0.72, options: [.drawsBeforeStartLocation])
    for _ in 0..<Int(w * h / 4200) {
        let x = rng.d(0, w); let y = rng.d(0, h)
        let len = rng.d(3, 13); let a = rng.d(0, .pi)
        ctx.setStrokeColor(wc(0.5, 0.42, 0.3, rng.d(0.03, 0.08)))
        ctx.setLineWidth(rng.d(0.5, 1.1))
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + cos(a) * len, y: y + sin(a) * len))
        ctx.strokePath()
    }
    for _ in 0..<20 {
        let x = rng.d(0, w); let y = rng.d(0, h); let r = rng.d(10, 70)
        ctx.setFillColor(wc(0.66, 0.55, 0.38, rng.d(0.02, 0.06)))
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
}

func blobPath(_ pts: [(Double, Double)], _ rng: inout WRNG, wobble: Double = 14) -> CGPath {
    let path = CGMutablePath()
    var scaled = pts.map { CGPoint(x: $0.0 * MW, y: $0.1 * MH) }
    if scaled.isEmpty { return path }
    scaled.append(scaled[0])
    path.move(to: scaled[0])
    for j in 1..<scaled.count {
        let prev = scaled[j - 1]
        let cur = scaled[j]
        let mid = CGPoint(x: (prev.x + cur.x) / 2 + rng.d(-wobble, wobble), y: (prev.y + cur.y) / 2 + rng.d(-wobble, wobble))
        path.addQuadCurve(to: cur, control: mid)
    }
    path.closeSubpath()
    return path
}

func drawWater(_ ctx: CGContext, _ poly: CGPath, _ rng: inout WRNG) {
    wFill(ctx, poly, wc(0.318, 0.412, 0.471, 0.14))
    ctx.saveGState()
    ctx.addPath(poly)
    ctx.clip()
    let r = poly.boundingBox
    var y = r.minY + 8
    while y < r.maxY {
        var x = r.minX
        let p = CGMutablePath()
        p.move(to: CGPoint(x: x, y: y))
        while x < r.maxX {
            let nx = x + rng.d(26, 44)
            p.addQuadCurve(to: CGPoint(x: nx, y: y + rng.d(-2, 2)), control: CGPoint(x: (x + nx) / 2, y: y - rng.d(5, 9)))
            x = nx + rng.d(8, 20)
            p.move(to: CGPoint(x: x, y: y))
        }
        wStroke(ctx, p, wc(0.318, 0.412, 0.471, 0.55), 1.3)
        y += rng.d(16, 24)
    }
    ctx.restoreGState()
    wStroke(ctx, poly, wInk, 2.6)
    let inner = CGMutablePath()
    inner.addPath(poly)
    ctx.saveGState()
    ctx.addPath(poly)
    ctx.clip()
    ctx.translateBy(x: 3, y: 3)
    wStroke(ctx, poly, wInkSoft, 1.1)
    ctx.restoreGState()
}

func drawRiver(_ ctx: CGContext, _ pts: [(Double, Double)], _ rng: inout WRNG, width: Double = 7) {
    let path = CGMutablePath()
    let scaled = pts.map { CGPoint(x: $0.0 * MW, y: $0.1 * MH) }
    path.move(to: scaled[0])
    for j in 1..<scaled.count {
        let prev = scaled[j - 1]
        let cur = scaled[j]
        path.addQuadCurve(to: cur, control: CGPoint(x: (prev.x + cur.x) / 2 + rng.d(-18, 18), y: (prev.y + cur.y) / 2 + rng.d(-18, 18)))
    }
    wStroke(ctx, path, wc(0.318, 0.412, 0.471, 0.75), width)
    wStroke(ctx, path, wInk.copy(alpha: 0.5)!, 1.2)
}

func drawMountains(_ ctx: CGContext, _ region: CGRect, count: Int, _ rng: inout WRNG) {
    for _ in 0..<count {
        let x = rng.d(region.minX, region.maxX)
        let y = rng.d(region.minY, region.maxY)
        let s = rng.d(20, 40)
        let m = CGMutablePath()
        m.move(to: CGPoint(x: x - s, y: y))
        m.addLine(to: CGPoint(x: x, y: y - s * rng.d(0.9, 1.3)))
        m.addLine(to: CGPoint(x: x + s, y: y))
        wStroke(ctx, m, wInk.copy(alpha: 0.8)!, 2.0)
        let shade = CGMutablePath()
        shade.move(to: CGPoint(x: x, y: y - s * 0.9))
        shade.addLine(to: CGPoint(x: x + s * 0.5, y: y))
        for t in stride(from: 0.25, through: 0.75, by: 0.25) {
            shade.move(to: CGPoint(x: x + s * 0.16 * t * 3, y: y - s * (0.9 - 0.8 * t)))
            shade.addLine(to: CGPoint(x: x + s * 0.55 * t + s * 0.18, y: y - rng.d(0, 4)))
        }
        wStroke(ctx, shade, wInkSoft, 1.1)
    }
}

func drawDunes(_ ctx: CGContext, _ region: CGRect, count: Int, _ rng: inout WRNG) {
    for _ in 0..<count {
        let x = rng.d(region.minX, region.maxX)
        let y = rng.d(region.minY, region.maxY)
        let s = rng.d(14, 30)
        let p = CGMutablePath()
        p.move(to: CGPoint(x: x - s, y: y))
        p.addQuadCurve(to: CGPoint(x: x + s, y: y), control: CGPoint(x: x, y: y - s * 0.55))
        wStroke(ctx, p, wInkSoft, 1.3)
        for _ in 0..<4 {
            let dx = rng.d(-s, s)
            ctx.setFillColor(wc(0.235, 0.196, 0.137, 0.3))
            ctx.fillEllipse(in: CGRect(x: x + dx, y: y + rng.d(4, 12), width: 1.8, height: 1.8))
        }
    }
}

func drawPalms(_ ctx: CGContext, at pts: [(Double, Double)], _ rng: inout WRNG) {
    for (fx, fy) in pts {
        let x = fx * MW; let y = fy * MH
        let t = CGMutablePath()
        t.move(to: CGPoint(x: x, y: y))
        t.addQuadCurve(to: CGPoint(x: x + 4, y: y - 26), control: CGPoint(x: x - 3, y: y - 14))
        wStroke(ctx, t, wInk, 2.4)
        for k in 0..<5 {
            let a = -Double.pi * 0.9 + Double(k) * .pi * 0.8 / 4
            let f = CGMutablePath()
            f.move(to: CGPoint(x: x + 4, y: y - 26))
            f.addQuadCurve(to: CGPoint(x: x + 4 + cos(a) * 16, y: y - 26 + sin(a) * 12 + 4),
                           control: CGPoint(x: x + 4 + cos(a) * 8, y: y - 30))
            wStroke(ctx, f, wInk.copy(alpha: 0.8)!, 1.3)
        }
    }
}

func compassRose(_ ctx: CGContext, at c: CGPoint, r: Double, _ rng: inout WRNG) {
    ctx.setStrokeColor(wGoldD)
    ctx.setLineWidth(1.6)
    ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.setStrokeColor(wInkSoft)
    ctx.setLineWidth(0.9)
    ctx.strokeEllipse(in: CGRect(x: c.x - r * 0.72, y: c.y - r * 0.72, width: r * 1.44, height: r * 1.44))
    for k in 0..<8 {
        let a = Double(k) * .pi / 4 - .pi / 2
        let big = k % 2 == 0
        let tip = CGPoint(x: c.x + cos(a) * (big ? r : r * 0.6), y: c.y + sin(a) * (big ? r : r * 0.6))
        let l = CGPoint(x: c.x + cos(a - 0.35) * r * 0.18, y: c.y + sin(a - 0.35) * r * 0.18)
        let rr = CGPoint(x: c.x + cos(a + 0.35) * r * 0.18, y: c.y + sin(a + 0.35) * r * 0.18)
        let star = CGMutablePath()
        star.move(to: l)
        star.addLine(to: tip)
        star.addLine(to: rr)
        star.closeSubpath()
        if big {
            wFill(ctx, star, k == 0 ? wGoldM : wPaperEdge)
        }
        wStroke(ctx, star, wInk, 1.2)
    }
    let font = CTFontCreateWithName("Georgia-Bold" as CFString, r * 0.34, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): wInk,
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "N", attributes: attrs))
    ctx.saveGState()
    ctx.translateBy(x: 0, y: MH)
    ctx.scaleBy(x: 1, y: -1)
    ctx.textPosition = CGPoint(x: c.x - r * 0.12, y: MH - (c.y - r - 8))
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func mapText(_ ctx: CGContext, _ text: String, at p: CGPoint, size: Double, color: CGColor, bold: Bool = true, italic: Bool = false) {
    let name = italic ? "Georgia-Italic" : (bold ? "Georgia-Bold" : "Georgia")
    let font = CTFontCreateWithName(name as CFString, size, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(str)
    let bounds = CTLineGetBoundsWithOptions(line, [.useOpticalBounds])
    ctx.saveGState()
    ctx.translateBy(x: 0, y: MH)
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(wPaper.copy(alpha: 0.75)!)
    ctx.fill(CGRect(x: p.x - bounds.width / 2 - 5, y: MH - p.y - bounds.height / 2 - 2, width: bounds.width + 10, height: bounds.height + 5))
    ctx.textPosition = CGPoint(x: p.x - bounds.width / 2, y: MH - p.y - bounds.height * 0.32)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}
