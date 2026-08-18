import Foundation
import CoreGraphics

let VW: Double = 900
let VH: Double = 675

func vHatchRect(_ ctx: CGContext, _ r: CGRect, angle: Double, gap: Double, col: CGColor, width: Double, _ rng: inout WRNG) {
    ctx.saveGState()
    ctx.clip(to: r)
    ctx.setStrokeColor(col)
    ctx.setLineWidth(width)
    let diag = sqrt(r.width * r.width + r.height * r.height)
    let n = Int(diag / gap) + 2
    let dirX = cos(angle); let dirY = sin(angle)
    let px = -dirY; let py = dirX
    for k in -n...n {
        let off = Double(k) * gap + rng.d(-1.4, 1.4)
        let cx = r.midX + px * off; let cy = r.midY + py * off
        ctx.move(to: CGPoint(x: cx - dirX * diag, y: cy - dirY * diag))
        ctx.addLine(to: CGPoint(x: cx + dirX * diag, y: cy + dirY * diag))
        ctx.strokePath()
    }
    ctx.restoreGState()
}

func vSun(_ ctx: CGContext, at c: CGPoint, r: Double, _ rng: inout WRNG) {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let sun = CGMutablePath()
    sun.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.saveGState()
    ctx.addPath(sun)
    ctx.clip()
    let grad = CGGradient(colorsSpace: cs, colors: [wGoldH, wGoldD] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: c.x, y: c.y - r), end: CGPoint(x: c.x, y: c.y + r), options: [])
    ctx.restoreGState()
    wStroke(ctx, sun, wGoldD, 1.6)
    for k in 0..<15 {
        let a = Double(k) * 2 * .pi / 15 + rng.d(-0.04, 0.04)
        let p = CGMutablePath()
        p.move(to: CGPoint(x: c.x + cos(a) * (r + 8), y: c.y + sin(a) * (r + 8)))
        p.addLine(to: CGPoint(x: c.x + cos(a) * (r + rng.d(20, 34)), y: c.y + sin(a) * (r + rng.d(20, 34))))
        wStroke(ctx, p, wGoldM.copy(alpha: 0.75)!, 1.4)
    }
}

func vGround(_ ctx: CGContext, yF: Double, _ rng: inout WRNG, tint: CGColor) {
    let y = VH * yF
    let band = CGMutablePath()
    band.move(to: CGPoint(x: -20, y: y))
    var x = -20.0
    var pts: [CGPoint] = [CGPoint(x: x, y: y)]
    while x < VW + 20 {
        let nx = min(x + rng.d(70, 130), VW + 20)
        pts.append(CGPoint(x: nx, y: y + rng.d(-6, 6)))
        x = nx
    }
    for j in 1..<pts.count {
        band.addQuadCurve(to: pts[j], control: CGPoint(x: (pts[j-1].x + pts[j].x) / 2, y: pts[j-1].y + rng.d(-7, 7)))
    }
    band.addLine(to: CGPoint(x: VW + 20, y: VH + 20))
    band.addLine(to: CGPoint(x: -20, y: VH + 20))
    band.closeSubpath()
    wFill(ctx, band, tint)
    let top = CGMutablePath()
    top.move(to: pts[0])
    for j in 1..<pts.count {
        top.addQuadCurve(to: pts[j], control: CGPoint(x: (pts[j-1].x + pts[j].x) / 2, y: pts[j-1].y))
    }
    wStroke(ctx, top, wInk, 2.6)
    vHatchRect(ctx, CGRect(x: 0, y: y, width: VW, height: VH - y), angle: 0.08, gap: 11, col: wInkSoft.copy(alpha: 0.3)!, width: 1.0, &rng)
}

func vCamel(_ ctx: CGContext, at base: CGPoint, s: Double, _ rng: inout WRNG) {
    let body = CGMutablePath()
    body.addEllipse(in: CGRect(x: base.x - s * 0.5, y: base.y - s * 0.42, width: s, height: s * 0.4))
    wFill(ctx, body, wPaper)
    wStroke(ctx, body, wInk, 2.2)
    let hump = CGMutablePath()
    hump.move(to: CGPoint(x: base.x - s * 0.2, y: base.y - s * 0.4))
    hump.addQuadCurve(to: CGPoint(x: base.x + s * 0.16, y: base.y - s * 0.4), control: CGPoint(x: base.x, y: base.y - s * 0.62))
    wStroke(ctx, hump, wInk, 2.2)
    let neck = CGMutablePath()
    neck.move(to: CGPoint(x: base.x + s * 0.44, y: base.y - s * 0.3))
    neck.addQuadCurve(to: CGPoint(x: base.x + s * 0.64, y: base.y - s * 0.72), control: CGPoint(x: base.x + s * 0.62, y: base.y - s * 0.44))
    wStroke(ctx, neck, wInk, s * 0.075)
    let head = CGMutablePath()
    head.addEllipse(in: CGRect(x: base.x + s * 0.56, y: base.y - s * 0.82, width: s * 0.2, height: s * 0.11))
    wFill(ctx, head, wPaper)
    wStroke(ctx, head, wInk, 1.8)
    for lx in [-0.34, -0.12, 0.1, 0.32] {
        let leg = CGMutablePath()
        leg.move(to: CGPoint(x: base.x + s * lx, y: base.y - s * 0.06))
        leg.addLine(to: CGPoint(x: base.x + s * lx + rng.d(-2, 2), y: base.y + s * 0.22))
        wStroke(ctx, leg, wInk, 3.0)
    }
}

func vTree(_ ctx: CGContext, at base: CGPoint, h: Double, _ rng: inout WRNG) {
    let trunk = CGMutablePath()
    trunk.move(to: CGPoint(x: base.x, y: base.y))
    trunk.addQuadCurve(to: CGPoint(x: base.x + h * 0.06, y: base.y - h * 0.5), control: CGPoint(x: base.x - h * 0.08, y: base.y - h * 0.3))
    wStroke(ctx, trunk, wInk, h * 0.05)
    let crown = CGMutablePath()
    crown.addEllipse(in: CGRect(x: base.x - h * 0.32, y: base.y - h, width: h * 0.68, height: h * 0.56))
    wFill(ctx, crown, wPaper.copy(alpha: 0.85)!)
    wStroke(ctx, crown, wInk, 2.0)
    wHatch(ctx, crown, angle: 0.55, gap: 7, col: wInkSoft.copy(alpha: 0.4)!, width: 1.0, &rng)
}

func vBoat(_ ctx: CGContext, at c: CGPoint, s: Double, _ rng: inout WRNG) {
    let hull = CGMutablePath()
    hull.move(to: CGPoint(x: c.x - s, y: c.y))
    hull.addQuadCurve(to: CGPoint(x: c.x + s, y: c.y), control: CGPoint(x: c.x, y: c.y + s * 0.62))
    hull.addLine(to: CGPoint(x: c.x + s * 0.82, y: c.y - s * 0.22))
    hull.addLine(to: CGPoint(x: c.x - s * 0.82, y: c.y - s * 0.22))
    hull.closeSubpath()
    wFill(ctx, hull, wPaper)
    wStroke(ctx, hull, wInk, 2.4)
    wHatch(ctx, hull, angle: 0.05, gap: 7, col: wInkSoft.copy(alpha: 0.4)!, width: 1.0, &rng)
    let mast = CGMutablePath()
    mast.move(to: CGPoint(x: c.x, y: c.y - s * 0.22))
    mast.addLine(to: CGPoint(x: c.x + s * 0.06, y: c.y - s * 1.3))
    wStroke(ctx, mast, wInk, 3.2)
    let sail = CGMutablePath()
    sail.move(to: CGPoint(x: c.x + s * 0.06, y: c.y - s * 1.26))
    sail.addQuadCurve(to: CGPoint(x: c.x + s * 0.66, y: c.y - s * 0.34), control: CGPoint(x: c.x + s * 0.72, y: c.y - s * 1.0))
    sail.addLine(to: CGPoint(x: c.x + s * 0.05, y: c.y - s * 0.34))
    sail.closeSubpath()
    wFill(ctx, sail, wPaper)
    wStroke(ctx, sail, wInk, 2.0)
}

func vWaves(_ ctx: CGContext, in r: CGRect, rows: Int, _ rng: inout WRNG) {
    for row in 0..<rows {
        let y = r.minY + r.height * Double(row) / Double(max(rows - 1, 1)) + rng.d(-4, 4)
        var x = r.minX + rng.d(0, 26)
        let p = CGMutablePath()
        p.move(to: CGPoint(x: x, y: y))
        while x < r.maxX - 14 {
            let seg = rng.d(34, 58)
            let nx = min(x + seg, r.maxX - 8)
            p.addQuadCurve(to: CGPoint(x: nx, y: y), control: CGPoint(x: x + seg / 2, y: y - rng.d(8, 14)))
            x = nx + rng.d(8, 22)
            p.move(to: CGPoint(x: x, y: y))
        }
        wStroke(ctx, p, row % 2 == 0 ? wInk.copy(alpha: 0.8)! : wInkSoft, 1.7)
    }
}

func renderVignette(_ ctx: CGContext, terrain: String, rng: inout WRNG) {
    var r = rng
    wPaperBase(ctx, VW, VH, &r)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let sky = CGGradient(colorsSpace: cs, colors: [wc(0.42, 0.48, 0.60, 0.22), wc(0.42, 0.48, 0.60, 0.0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: VH * 0.6), options: [])
    switch terrain {
    case "desert":
        vSun(ctx, at: CGPoint(x: VW * r.d(0.62, 0.8), y: VH * 0.2), r: 42, &r)
        vGround(ctx, yF: 0.66, &r, tint: wc(0.72, 0.6, 0.38, 0.14))
        for _ in 0..<7 {
            let dp = CGMutablePath()
            let dx = r.d(60, VW - 60); let dy = r.d(VH * 0.7, VH * 0.92)
            dp.move(to: CGPoint(x: dx - 30, y: dy))
            dp.addQuadCurve(to: CGPoint(x: dx + 30, y: dy), control: CGPoint(x: dx, y: dy - 16))
            wStroke(ctx, dp, wInkSoft, 1.3)
        }
        vCamel(ctx, at: CGPoint(x: VW * r.d(0.3, 0.5), y: VH * 0.62), s: 130, &r)
        vCamel(ctx, at: CGPoint(x: VW * r.d(0.6, 0.72), y: VH * 0.7), s: 90, &r)
    case "hills":
        vSun(ctx, at: CGPoint(x: VW * 0.76, y: VH * 0.2), r: 36, &r)
        for (i, hf) in [0.42, 0.52].enumerated() {
            let hill = CGMutablePath()
            let cx = VW * (0.24 + Double(i) * 0.5)
            hill.move(to: CGPoint(x: cx - 380, y: VH * (hf + 0.28)))
            hill.addQuadCurve(to: CGPoint(x: cx + 380, y: VH * (hf + 0.28)), control: CGPoint(x: cx, y: VH * (hf - 0.2)))
            wStroke(ctx, hill, wInk, 2.2)
            let clip = CGMutablePath()
            clip.addPath(hill)
            clip.closeSubpath()
            wHatch(ctx, clip, angle: .pi / 3.2, gap: 9, col: wInkSoft.copy(alpha: 0.3)!, width: 1.0, &r)
        }
        vGround(ctx, yF: 0.72, &r, tint: wc(0.45, 0.52, 0.36, 0.12))
        vTree(ctx, at: CGPoint(x: VW * r.d(0.2, 0.32), y: VH * 0.7), h: 180, &r)
        vTree(ctx, at: CGPoint(x: VW * r.d(0.62, 0.78), y: VH * 0.74), h: 130, &r)
    case "river":
        vGround(ctx, yF: 0.6, &r, tint: wc(0.45, 0.52, 0.36, 0.1))
        let riv = CGMutablePath()
        riv.move(to: CGPoint(x: VW * 0.34, y: VH * 0.6))
        riv.addQuadCurve(to: CGPoint(x: VW * 0.2, y: VH + 20), control: CGPoint(x: VW * 0.22, y: VH * 0.8))
        riv.addLine(to: CGPoint(x: VW * 0.62, y: VH + 20))
        riv.addQuadCurve(to: CGPoint(x: VW * 0.52, y: VH * 0.6), control: CGPoint(x: VW * 0.52, y: VH * 0.8))
        riv.closeSubpath()
        wFill(ctx, riv, wc(0.318, 0.412, 0.471, 0.2))
        wStroke(ctx, riv, wInk, 2.0)
        vWaves(ctx, in: CGRect(x: VW * 0.24, y: VH * 0.66, width: VW * 0.32, height: VH * 0.3), rows: 5, &r)
        for k in 0..<9 {
            let reed = CGMutablePath()
            let x = VW * (k < 5 ? r.d(0.08, 0.2) : r.d(0.6, 0.72))
            let y = VH * r.d(0.68, 0.9)
            reed.move(to: CGPoint(x: x, y: y))
            reed.addQuadCurve(to: CGPoint(x: x + r.d(-10, 10), y: y - r.d(60, 110)), control: CGPoint(x: x, y: y - 40))
            wStroke(ctx, reed, wInk.copy(alpha: 0.75)!, 1.9)
        }
        vTree(ctx, at: CGPoint(x: VW * 0.8, y: VH * 0.62), h: 150, &r)
    case "sea":
        vSun(ctx, at: CGPoint(x: VW * 0.24, y: VH * 0.18), r: 38, &r)
        let hor = CGMutablePath()
        hor.move(to: CGPoint(x: -10, y: VH * 0.44))
        hor.addLine(to: CGPoint(x: VW + 10, y: VH * 0.44))
        wStroke(ctx, hor, wInk.copy(alpha: 0.7)!, 1.8)
        vWaves(ctx, in: CGRect(x: 0, y: VH * 0.48, width: VW, height: VH * 0.48), rows: 8, &r)
        vBoat(ctx, at: CGPoint(x: VW * r.d(0.4, 0.6), y: VH * 0.6), s: 130, &r)
        for k in 0..<3 {
            let bird = CGMutablePath()
            let bx = VW * r.d(0.5, 0.86); let by = VH * r.d(0.12, 0.3)
            bird.move(to: CGPoint(x: bx - 14, y: by))
            bird.addQuadCurve(to: CGPoint(x: bx, y: by - 7), control: CGPoint(x: bx - 7, y: by - 10))
            bird.addQuadCurve(to: CGPoint(x: bx + 14, y: by), control: CGPoint(x: bx + 7, y: by - 10))
            wStroke(ctx, bird, wInk.copy(alpha: 0.7)!, 1.5)
            _ = k
        }
    case "city":
        vGround(ctx, yF: 0.78, &r, tint: wc(0.6, 0.5, 0.34, 0.1))
        let wallY = VH * 0.62
        let wall = CGMutablePath()
        wall.addRect(CGRect(x: VW * 0.12, y: wallY - 120, width: VW * 0.76, height: 120))
        wFill(ctx, wall, wPaper)
        wStroke(ctx, wall, wInk, 2.6)
        for row in 0..<4 {
            let y = wallY - Double(row) * 30
            let lp = CGMutablePath()
            lp.move(to: CGPoint(x: VW * 0.12, y: y))
            lp.addLine(to: CGPoint(x: VW * 0.88, y: y))
            wStroke(ctx, lp, wInk.copy(alpha: 0.4)!, 1.1)
            var bx = VW * 0.12 + (row % 2 == 0 ? 0 : 40)
            while bx < VW * 0.88 {
                let vp = CGMutablePath()
                vp.move(to: CGPoint(x: bx, y: y - 30))
                vp.addLine(to: CGPoint(x: bx, y: y))
                wStroke(ctx, vp, wInk.copy(alpha: 0.3)!, 1.0)
                bx += 80
            }
        }
        for k in 0..<10 {
            let b = CGMutablePath()
            b.addRect(CGRect(x: VW * 0.13 + Double(k) * VW * 0.075, y: wallY - 138, width: 26, height: 18))
            wFill(ctx, b, wPaper)
            wStroke(ctx, b, wInk, 1.6)
        }
        for tx in [VW * 0.2, VW * 0.8] {
            let tower = CGMutablePath()
            tower.addRect(CGRect(x: tx - 40, y: wallY - 220, width: 80, height: 220))
            wFill(ctx, tower, wPaper)
            wStroke(ctx, tower, wInk, 2.4)
            wHatch(ctx, tower, angle: 0.3, gap: 9, col: wInkSoft.copy(alpha: 0.3)!, width: 1.0, &r)
        }
        let gate = CGMutablePath()
        gate.move(to: CGPoint(x: VW * 0.46, y: wallY))
        gate.addLine(to: CGPoint(x: VW * 0.46, y: wallY - 64))
        gate.addQuadCurve(to: CGPoint(x: VW * 0.54, y: wallY - 64), control: CGPoint(x: VW * 0.5, y: wallY - 100))
        gate.addLine(to: CGPoint(x: VW * 0.54, y: wallY))
        gate.closeSubpath()
        wFill(ctx, gate, wInk.copy(alpha: 0.75)!)
        vTree(ctx, at: CGPoint(x: VW * r.d(0.06, 0.1) + 20, y: VH * 0.8), h: 120, &r)
    case "mountain":
        vSun(ctx, at: CGPoint(x: VW * 0.8, y: VH * 0.16), r: 34, &r)
        let peak = CGMutablePath()
        peak.move(to: CGPoint(x: VW * 0.08, y: VH * 0.8))
        peak.addLine(to: CGPoint(x: VW * 0.42, y: VH * 0.16))
        peak.addLine(to: CGPoint(x: VW * 0.72, y: VH * 0.8))
        peak.closeSubpath()
        wFill(ctx, peak, wPaper)
        wStroke(ctx, peak, wInk, 2.8)
        wHatch(ctx, peak, angle: .pi / 2.8, gap: 9, col: wInkSoft.copy(alpha: 0.4)!, width: 1.1, &r)
        let peak2 = CGMutablePath()
        peak2.move(to: CGPoint(x: VW * 0.5, y: VH * 0.8))
        peak2.addLine(to: CGPoint(x: VW * 0.78, y: VH * 0.34))
        peak2.addLine(to: CGPoint(x: VW * 0.98, y: VH * 0.8))
        peak2.closeSubpath()
        wFill(ctx, peak2, wPaper)
        wStroke(ctx, peak2, wInk, 2.4)
        wHatch(ctx, peak2, angle: .pi / 3.1, gap: 10, col: wInkSoft.copy(alpha: 0.35)!, width: 1.0, &r)
        for k in 0..<3 {
            let cl = CGMutablePath()
            let cx = VW * r.d(0.2, 0.6); let cy = VH * r.d(0.12, 0.26)
            var x = cx - 60.0
            cl.move(to: CGPoint(x: x, y: cy))
            while x < cx + 60 {
                let nx = x + r.d(24, 40)
                cl.addQuadCurve(to: CGPoint(x: nx, y: cy), control: CGPoint(x: (x + nx) / 2, y: cy - r.d(12, 20)))
                x = nx
            }
            wStroke(ctx, cl, wInk.copy(alpha: 0.6)!, 1.6)
            _ = k
        }
        vGround(ctx, yF: 0.8, &r, tint: wc(0.5, 0.5, 0.4, 0.1))
    default:
        vSun(ctx, at: CGPoint(x: VW * 0.72, y: VH * 0.2), r: 38, &r)
        vGround(ctx, yF: 0.62, &r, tint: wc(0.5, 0.55, 0.4, 0.1))
        for k in 0..<3 {
            let tx = VW * (0.2 + Double(k) * 0.28) + r.d(-30, 30)
            let tent = CGMutablePath()
            tent.move(to: CGPoint(x: tx - 70, y: VH * 0.74))
            tent.addLine(to: CGPoint(x: tx, y: VH * 0.62))
            tent.addLine(to: CGPoint(x: tx + 70, y: VH * 0.74))
            tent.closeSubpath()
            wFill(ctx, tent, wPaper)
            wStroke(ctx, tent, wInk, 2.2)
            wHatch(ctx, tent, angle: .pi / 2.6, gap: 8, col: wInkSoft.copy(alpha: 0.35)!, width: 1.0, &r)
        }
        for _ in 0..<12 {
            let g = CGMutablePath()
            let gx = r.d(40, VW - 40); let gy = VH * r.d(0.8, 0.94)
            g.move(to: CGPoint(x: gx, y: gy))
            g.addLine(to: CGPoint(x: gx + r.d(-6, 6), y: gy - r.d(10, 22)))
            wStroke(ctx, g, wInkSoft, 1.2)
        }
    }
    let border = CGRect(x: 18, y: 18, width: VW - 36, height: VH - 36)
    ctx.setStrokeColor(wInk.copy(alpha: 0.75)!)
    ctx.setLineWidth(2.6)
    ctx.stroke(border)
    ctx.setStrokeColor(wGoldD)
    ctx.setLineWidth(1.2)
    ctx.stroke(border.insetBy(dx: 6, dy: 6))
    let cs2 = CGColorSpace(name: CGColorSpace.sRGB)!
    let vin = CGGradient(colorsSpace: cs2, colors: [wc(0, 0, 0, 0), wc(0.25, 0.18, 0.08, 0.13)] as CFArray, locations: [0.72, 1])!
    ctx.drawRadialGradient(vin, startCenter: CGPoint(x: VW / 2, y: VH / 2), startRadius: 0,
                           endCenter: CGPoint(x: VW / 2, y: VH / 2), endRadius: VH * 0.85, options: [])
    rng = r
}
