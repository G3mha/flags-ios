import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Brazil flag, official geometry on a 20 x 14 canvas.
// Rhombus vertices sit 1.7 units in from each edge; blue disc radius 3.5 at centre.
func drawBrazil(in ctx: CGContext, size: CGFloat) {
    let u = size / 20.0                      // one flag-unit in points
    let cx = size / 2, cy = size / 2
    let halfH = 7 * u                         // flag is 14 units tall

    ctx.setFillColor(CGColor(red: 0.0, green: 0.608, blue: 0.282, alpha: 1))   // #009B48
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Yellow rhombus
    ctx.setFillColor(CGColor(red: 1.0, green: 0.867, blue: 0.0, alpha: 1))     // #FFDD00
    ctx.beginPath()
    ctx.move(to: CGPoint(x: cx - (10 - 1.7) * u, y: cy))
    ctx.addLine(to: CGPoint(x: cx, y: cy + halfH - 1.7 * u))
    ctx.addLine(to: CGPoint(x: cx + (10 - 1.7) * u, y: cy))
    ctx.addLine(to: CGPoint(x: cx, y: cy - halfH + 1.7 * u))
    ctx.closePath()
    ctx.fillPath()

    // Blue celestial disc
    let r = 3.5 * u
    ctx.setFillColor(CGColor(red: 0.0, green: 0.157, blue: 0.494, alpha: 1))   // #00287E
    ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))

    // White banner sweeping across the disc
    ctx.saveGState()
    ctx.beginPath()
    ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    ctx.clip()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let bandR = r * 2.05
    ctx.beginPath()
    ctx.addArc(center: CGPoint(x: cx, y: cy - bandR * 0.72), radius: bandR,
               startAngle: .pi * 0.16, endAngle: .pi * 0.84, clockwise: false)
    ctx.addArc(center: CGPoint(x: cx, y: cy - bandR * 0.72), radius: bandR * 1.11,
               startAngle: .pi * 0.84, endAngle: .pi * 0.16, clockwise: true)
    ctx.closePath()
    ctx.fillPath()

    // A scatter of stars so the disc doesn't read as a plain blob at complication size
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    let stars: [(CGFloat, CGFloat, CGFloat)] = [
        (-0.42, 0.44, 0.075), (-0.10, 0.56, 0.055), (0.30, 0.40, 0.065),
        (0.52, 0.10, 0.050), (-0.55, 0.02, 0.055), (-0.22, -0.30, 0.070),
        (0.12, -0.16, 0.050), (0.40, -0.44, 0.060), (-0.02, -0.62, 0.055),
        (0.62, -0.20, 0.045), (-0.38, -0.56, 0.045), (0.20, 0.72, 0.045),
    ]
    for (sx, sy, sr) in stars {
        let p = CGPoint(x: cx + sx * r, y: cy + sy * r)
        ctx.fillEllipse(in: CGRect(x: p.x - sr * r, y: p.y - sr * r,
                                   width: 2 * sr * r, height: 2 * sr * r))
    }
    ctx.restoreGState()
}

func write(size: Int, to url: URL) {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawBrazil(in: ctx, size: CGFloat(size))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.lastPathComponent) (\(size)x\(size))")
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
write(size: 256, to: outDir.appendingPathComponent("flag-br.png"))
write(size: 512, to: outDir.appendingPathComponent("flag-br@2x.png"))
write(size: 768, to: outDir.appendingPathComponent("flag-br@3x.png"))
