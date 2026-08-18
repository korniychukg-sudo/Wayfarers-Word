import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let S: Double = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.translateBy(x: 0, y: S)
ctx.scaleBy(x: 1, y: -1)

func c(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

var seed: UInt64 = 55
func rnd() -> Double {
    seed = seed &* 6364136223846793005 &+ 1442695040888963407
    return Double((seed >> 33) % 100000) / 100000.0
}

let sky = CGGradient(colorsSpace: cs, colors: [c(0.16, 0.20, 0.33), c(0.38, 0.30, 0.30), c(0.72, 0.46, 0.26)] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: S * 0.72), options: [])

for _ in 0..<24 {
    let x = rnd() * S
    let y = rnd() * S * 0.4
    let r = 2.0 + rnd() * 3.2
    ctx.setFillColor(c(0.95, 0.9, 0.7, 0.3 + rnd() * 0.5))
    ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
}

let starC = CGPoint(x: S * 0.72, y: S * 0.2)
for k in 0..<12 {
    let a = Double(k) * .pi / 6
    let ray = CGMutablePath()
    ray.move(to: CGPoint(x: starC.x + cos(a) * 38, y: starC.y + sin(a) * 38))
    ray.addLine(to: CGPoint(x: starC.x + cos(a) * (60 + Double(k % 2) * 18), y: starC.y + sin(a) * (60 + Double(k % 2) * 18)))
    ctx.addPath(ray)
    ctx.setStrokeColor(c(0.95, 0.85, 0.5, 0.85))
    ctx.setLineWidth(5)
    ctx.strokePath()
}
let star = CGMutablePath()
for k in 0..<8 {
    let a = Double(k) * .pi / 4 - .pi / 2
    let rr = k % 2 == 0 ? 40.0 : 15.0
    let pt = CGPoint(x: starC.x + cos(a) * rr, y: starC.y + sin(a) * rr)
    if k == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
}
star.closeSubpath()
ctx.addPath(star)
ctx.setFillColor(c(0.96, 0.87, 0.55))
ctx.fillPath()
ctx.addPath(star)
ctx.setStrokeColor(c(0.55, 0.38, 0.1))
ctx.setLineWidth(3)
ctx.strokePath()

let sunset = CGGradient(colorsSpace: cs, colors: [c(0.9, 0.65, 0.3, 0.5), c(0.9, 0.65, 0.3, 0.0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(sunset, startCenter: CGPoint(x: S * 0.3, y: S * 0.66), startRadius: 10, endCenter: CGPoint(x: S * 0.3, y: S * 0.66), endRadius: S * 0.5, options: [])

func duneBand(_ yTop: Double, _ tone: CGColor, _ wob: Double) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: -20, y: yTop))
    var x = -20.0
    while x < S + 20 {
        let nx = x + 180
        p.addQuadCurve(to: CGPoint(x: nx, y: yTop + rnd() * wob - wob / 2), control: CGPoint(x: (x + nx) / 2, y: yTop - wob))
        x = nx
    }
    p.addLine(to: CGPoint(x: S + 20, y: S + 20))
    p.addLine(to: CGPoint(x: -20, y: S + 20))
    p.closeSubpath()
    ctx.addPath(p)
    ctx.setFillColor(tone)
    ctx.fillPath()
}

duneBand(S * 0.66, c(0.78, 0.60, 0.36), 40)
duneBand(S * 0.76, c(0.68, 0.50, 0.28), 34)
duneBand(S * 0.86, c(0.55, 0.39, 0.21), 28)

let ridge = CGMutablePath()
ridge.move(to: CGPoint(x: -10, y: S * 0.78))
ridge.addQuadCurve(to: CGPoint(x: S + 10, y: S * 0.8), control: CGPoint(x: S * 0.5, y: S * 0.72))
ctx.addPath(ridge)
ctx.setStrokeColor(c(0.35, 0.22, 0.1, 0.5))
ctx.setLineWidth(4)
ctx.strokePath()

func camel(_ base: CGPoint, _ s: Double, _ tone: CGColor) {
    let sil = CGMutablePath()
    sil.move(to: CGPoint(x: base.x - s * 0.5, y: base.y - s * 0.1))
    sil.addQuadCurve(to: CGPoint(x: base.x - s * 0.42, y: base.y - s * 0.4), control: CGPoint(x: base.x - s * 0.56, y: base.y - s * 0.3))
    sil.addQuadCurve(to: CGPoint(x: base.x - s * 0.05, y: base.y - s * 0.44), control: CGPoint(x: base.x - s * 0.26, y: base.y - s * 0.42))
    sil.addQuadCurve(to: CGPoint(x: base.x + s * 0.2, y: base.y - s * 0.46), control: CGPoint(x: base.x + s * 0.08, y: base.y - s * 0.72))
    sil.addQuadCurve(to: CGPoint(x: base.x + s * 0.4, y: base.y - s * 0.36), control: CGPoint(x: base.x + s * 0.32, y: base.y - s * 0.44))
    sil.addLine(to: CGPoint(x: base.x + s * 0.52, y: base.y - s * 0.78))
    sil.addQuadCurve(to: CGPoint(x: base.x + s * 0.62, y: base.y - s * 0.88), control: CGPoint(x: base.x + s * 0.52, y: base.y - s * 0.88))
    sil.addLine(to: CGPoint(x: base.x + s * 0.78, y: base.y - s * 0.84))
    sil.addQuadCurve(to: CGPoint(x: base.x + s * 0.62, y: base.y - s * 0.76), control: CGPoint(x: base.x + s * 0.7, y: base.y - s * 0.76))
    sil.addLine(to: CGPoint(x: base.x + s * 0.6, y: base.y - s * 0.3))
    sil.addQuadCurve(to: CGPoint(x: base.x + s * 0.5, y: base.y - s * 0.06), control: CGPoint(x: base.x + s * 0.58, y: base.y - s * 0.12))
    sil.closeSubpath()
    ctx.addPath(sil)
    ctx.setFillColor(tone)
    ctx.fillPath()
    for (lx, lh, fwd) in [(-0.4, 0.4, -0.02), (-0.22, 0.42, 0.02), (0.26, 0.4, -0.02), (0.44, 0.42, 0.03)] {
        let leg = CGMutablePath()
        leg.move(to: CGPoint(x: base.x + s * lx, y: base.y - s * 0.14))
        leg.addLine(to: CGPoint(x: base.x + s * (lx + fwd), y: base.y + s * lh))
        ctx.addPath(leg)
        ctx.setStrokeColor(tone)
        ctx.setLineWidth(s * 0.075)
        ctx.setLineCap(.round)
        ctx.strokePath()
    }
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: base.x - s * 0.48, y: base.y - s * 0.36))
    tail.addQuadCurve(to: CGPoint(x: base.x - s * 0.6, y: base.y - s * 0.08), control: CGPoint(x: base.x - s * 0.62, y: base.y - s * 0.28))
    ctx.addPath(tail)
    ctx.setStrokeColor(tone)
    ctx.setLineWidth(s * 0.035)
    ctx.strokePath()
    let rider = CGMutablePath()
    rider.move(to: CGPoint(x: base.x - s * 0.02, y: base.y - s * 0.52))
    rider.addQuadCurve(to: CGPoint(x: base.x + 0.02 * s, y: base.y - s * 0.86), control: CGPoint(x: base.x - s * 0.12, y: base.y - s * 0.74))
    rider.addQuadCurve(to: CGPoint(x: base.x + s * 0.14, y: base.y - s * 0.56), control: CGPoint(x: base.x + s * 0.16, y: base.y - s * 0.76))
    rider.closeSubpath()
    ctx.addPath(rider)
    ctx.setFillColor(tone)
    ctx.fillPath()
    let riderHead = CGMutablePath()
    riderHead.addEllipse(in: CGRect(x: base.x - s * 0.05, y: base.y - s * 0.98, width: s * 0.14, height: s * 0.14))
    ctx.addPath(riderHead)
    ctx.setFillColor(tone)
    ctx.fillPath()
}

camel(CGPoint(x: S * 0.42, y: S * 0.8), 320, c(0.20, 0.13, 0.08))
camel(CGPoint(x: S * 0.72, y: S * 0.85), 190, c(0.24, 0.16, 0.1))

let road = CGMutablePath()
road.move(to: CGPoint(x: S * 0.08, y: S * 0.97))
road.addQuadCurve(to: CGPoint(x: S * 0.94, y: S * 0.9), control: CGPoint(x: S * 0.5, y: S * 1.02))
ctx.setLineCap(.round)
ctx.addPath(road)
ctx.setStrokeColor(c(0.95, 0.83, 0.45, 0.9))
ctx.setLineWidth(7)
ctx.setLineDash(phase: 0, lengths: [26, 18])
ctx.strokePath()
ctx.setLineDash(phase: 0, lengths: [])

let vin = CGGradient(colorsSpace: cs, colors: [c(0, 0, 0, 0), c(0.08, 0.05, 0.1, 0.38)] as CFArray, locations: [0.7, 1])!
ctx.drawRadialGradient(vin, startCenter: CGPoint(x: S / 2, y: S / 2), startRadius: 0, endCenter: CGPoint(x: S / 2, y: S / 2), endRadius: S * 0.74, options: [])

let img = ctx.makeImage()!
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("icon written")
