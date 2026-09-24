// Renders the flag SVGs to PNG using WebKit.
//
// Xcode's asset catalogues accept SVG but implement only a subset of it: 71 of
// these flags use clipPath and 60 use <use>, and those render wrong — Burundi
// came out as a black square, Cameroon as yellow smears. WebKit is a complete
// SVG engine and is already on the machine, so this snapshots each file rather
// than adding a dependency.
//
// Usage: swift Tools/rasterise.swift <catalogue> [pixels]

import AppKit
import WebKit

let args = CommandLine.arguments
guard args.count > 1 else {
    print("usage: rasterise.swift <catalogue.xcassets> [pixels]")
    exit(1)
}
let catalogue = URL(fileURLWithPath: args[1])
let side = args.count > 2 ? Int(args[2])! : 480

let imagesets = try FileManager.default
    .contentsOfDirectory(at: catalogue, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "imageset" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

final class Renderer: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    private let window: NSWindow
    private var done: ((NSImage?) -> Void)?
    private var currentToken = UUID()

    init(side: Int) {
        let frame = NSRect(x: 0, y: 0, width: side, height: side)
        webView = WKWebView(frame: frame, configuration: WKWebViewConfiguration())
        // An unhosted WKWebView does not reliably produce snapshots; it needs a
        // real window backing it, off-screen so nothing appears on the desktop.
        window = NSWindow(contentRect: frame,
                          styleMask: [.borderless],
                          backing: .buffered,
                          defer: false)
        window.contentView = webView
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderBack(nil)
        super.init()
        webView.navigationDelegate = self
    }

    func render(svg: String, completion: @escaping (NSImage?) -> Void) {
        done = completion
        // Watchdog: one SVG that never finishes loading must not stall the run.
        let token = UUID()
        currentToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.currentToken == token, let pending = self.done else { return }
            self.done = nil
            pending(nil)
        }
        // Strip any width/height so the SVG scales to the viewport; the
        // viewBox is what defines its geometry.
        let html = """
        <html><head><style>
        html,body{margin:0;padding:0;background:transparent;}
        svg{display:block;width:100vw;height:100vh;}
        </style></head><body>\(svg)</body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // One runloop turn so layout settles before the snapshot.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds
            webView.takeSnapshot(with: config) { image, _ in
                let pending = self.done
                self.done = nil
                pending?(image)
            }
        }
    }
}

func png(from image: NSImage, side: Int) -> Data? {
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: side, height: side)
    return rep.representation(using: .png, properties: [.compressionFactor: 1.0])
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let renderer = Renderer(side: side)
var index = 0
var failures: [String] = []

func next() {
    guard index < imagesets.count else {
        print("rendered \(imagesets.count - failures.count)/\(imagesets.count)")
        if !failures.isEmpty { print("failed: \(failures.joined(separator: ", "))") }
        exit(failures.isEmpty ? 0 : 1)
    }
    let set = imagesets[index]
    index += 1
    let name = set.deletingPathExtension().lastPathComponent
    guard let svgURL = try? FileManager.default.contentsOfDirectory(at: set, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "svg" }),
          let svg = try? String(contentsOf: svgURL, encoding: .utf8) else {
        failures.append(name)
        DispatchQueue.main.async { next() }
        return
    }

    renderer.render(svg: svg) { image in
        defer { DispatchQueue.main.async { next() } }
        guard let image, let data = png(from: image, side: side) else {
            failures.append(name); return
        }
        let out = set.appendingPathComponent("\(name).png")
        try? data.write(to: out)
        try? FileManager.default.removeItem(at: svgURL)
        let contents = """
        {
          "images" : [
            { "filename" : "\(name).png", "idiom" : "universal" }
          ],
          "info" : { "author" : "xcode", "version" : 1 }
        }
        """
        try? contents.write(to: set.appendingPathComponent("Contents.json"),
                            atomically: true, encoding: .utf8)
        if index % 50 == 0 { print("  \(index)/\(imagesets.count)") }
    }
}

DispatchQueue.main.async { next() }
app.run()
