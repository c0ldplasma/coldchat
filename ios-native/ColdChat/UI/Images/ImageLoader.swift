import ImageIO
import UIKit
import WebKit

/// Loads and caches remote images, including animated GIF and WebP emotes and SVG badges.
@MainActor
final class ImageLoader {
    static let shared = ImageLoader()

    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let session: URLSession

    private init() {
        memory.totalCostLimit = 120 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        // Emote and badge CDNs send long cache lifetimes; the disk cache keeps them across launches and offline.
        configuration.urlCache = URLCache(memoryCapacity: 16 * 1024 * 1024, diskCapacity: 400 * 1024 * 1024, directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("Images"))
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
    }

    func cached(_ url: URL, maxPixelSize: CGFloat) -> UIImage? {
        memory.object(forKey: key(url, maxPixelSize) as NSString)
    }

    func image(_ url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        let key = key(url, maxPixelSize)
        if let cached = memory.object(forKey: key as NSString) { return cached }
        if let running = inFlight[key] { return await running.value }

        let session = session
        let task = Task<UIImage?, Never> {
            guard let (data, _) = try? await session.data(from: url) else { return nil }
            let image: UIImage?
            if Self.isSVG(data, url: url) {
                image = await SVGRasterizer.shared.rasterize(data, pixelSize: maxPixelSize)
            } else {
                image = await Task.detached(priority: .utility) { Self.decode(data, maxPixelSize: maxPixelSize) }.value
            }
            return image
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            let frames = max(1, image.images?.count ?? 1)
            let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4) * frames
            memory.setObject(image, forKey: key as NSString, cost: cost)
        }
        return image
    }

    private func key(_ url: URL, _ maxPixelSize: CGFloat) -> String { "\(Int(maxPixelSize))|\(url.absoluteString)" }

    private nonisolated static func isSVG(_ data: Data, url: URL) -> Bool {
        if url.pathExtension.lowercased() == "svg" { return true }
        let head = String(decoding: data.prefix(256), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return head.hasPrefix("<svg") || (head.hasPrefix("<?xml") && head.contains("<svg"))
    }

    /// Decodes every frame, downscaled to [maxPixelSize], into an animated image when there's more than one.
    nonisolated static func decode(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return UIImage(data: data) }
        let count = CGImageSourceGetCount(source)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        if count <= 1 {
            guard let frame = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return UIImage(data: data) }
            return UIImage(cgImage: frame, scale: UIScreen.mainScale, orientation: .up)
        }

        var frames: [UIImage] = []
        var duration: Double = 0
        for index in 0..<count {
            guard let frame = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else { continue }
            frames.append(UIImage(cgImage: frame, scale: UIScreen.mainScale, orientation: .up))
            duration += frameDelay(source, index)
        }
        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: duration)
    }

    private nonisolated static func frameDelay(_ source: CGImageSource, _ index: Int) -> Double {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        let dictionaries = [kCGImagePropertyGIFDictionary, kCGImagePropertyWebPDictionary, kCGImagePropertyPNGDictionary]
        for key in dictionaries {
            guard let info = properties[key] as? [CFString: Any] else { continue }
            let unclamped = info[kCGImagePropertyGIFUnclampedDelayTime] ?? info[kCGImagePropertyWebPUnclampedDelayTime] ?? info[kCGImagePropertyAPNGUnclampedDelayTime]
            let clamped = info[kCGImagePropertyGIFDelayTime] ?? info[kCGImagePropertyWebPDelayTime] ?? info[kCGImagePropertyAPNGDelayTime]
            if let delay = (unclamped as? Double) ?? (clamped as? Double), delay > 0.011 { return delay }
            return 0.1
        }
        return 0.1
    }
}

extension UIScreen {
    /// The display scale, readable from the decoding threads. Set once at launch.
    nonisolated(unsafe) static var mainScale: CGFloat = 3
}

/// Draws SVGs (BetterTTV badges) by rendering them in an offscreen web view and taking a snapshot. UIKit has no
/// public SVG renderer for downloaded files.
@MainActor
final class SVGRasterizer {
    static let shared = SVGRasterizer()

    private var webView: WKWebView?
    private var queue: [(Data, CGFloat, CheckedContinuation<UIImage?, Never>)] = []
    private var busy = false

    func rasterize(_ data: Data, pixelSize: CGFloat) async -> UIImage? {
        await withCheckedContinuation { continuation in
            queue.append((data, pixelSize, continuation))
            next()
        }
    }

    private func next() {
        guard !busy, !queue.isEmpty else { return }
        busy = true
        let (data, pixelSize, continuation) = queue.removeFirst()
        let points = max(1, pixelSize / UIScreen.main.scale)
        let webView = self.webView ?? {
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            let view = WKWebView(frame: CGRect(x: 0, y: 0, width: points, height: points), configuration: configuration)
            view.isOpaque = false
            view.backgroundColor = .clear
            view.scrollView.backgroundColor = .clear
            self.webView = view
            return view
        }()
        webView.frame = CGRect(x: 0, y: 0, width: points, height: points)
        let svg = data.base64EncodedString()
        let html = """
        <html><head><meta name="viewport" content="width=\(Int(points)),initial-scale=1"><style>html,body{margin:0;background:transparent}img{width:100vw;height:100vh;object-fit:contain}</style></head>
        <body><img src="data:image/svg+xml;base64,\(svg)"></body></html>
        """
        let delegate = LoadDelegate { [weak self] in
            let configuration = WKSnapshotConfiguration()
            configuration.rect = CGRect(x: 0, y: 0, width: points, height: points)
            configuration.afterScreenUpdates = true
            webView.takeSnapshot(with: configuration) { image, _ in
                continuation.resume(returning: image)
                self?.busy = false
                self?.next()
            }
        }
        objc_setAssociatedObject(webView, &LoadDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN)
        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: nil)
    }

    private final class LoadDelegate: NSObject, WKNavigationDelegate {
        nonisolated(unsafe) static var key = 0
        let done: () -> Void
        private var finished = false

        init(done: @escaping () -> Void) {
            self.done = done
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            finish()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            finish()
        }

        private func finish() {
            guard !finished else { return }
            finished = true
            // Give the image a frame to decode before the snapshot.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.done() }
        }
    }
}
