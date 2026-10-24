import SwiftUI
import UIKit

/// A remote image at a fixed height, as wide as its aspect ratio needs. Animates GIF and WebP.
struct RemoteImage: View {
    let url: URL?
    let height: CGFloat
    var placeholderWidth: CGFloat?

    @State private var image: UIImage?
    @Environment(\.displayScale) private var displayScale

    private var pixelSize: CGFloat { max(height * displayScale * 2, 64) }

    var body: some View {
        Group {
            if let image, image.size.height > 0 {
                AnimatedImageView(image: image)
                    .frame(width: height * image.size.width / image.size.height, height: height)
            } else {
                Color.clear.frame(width: placeholderWidth ?? height, height: height)
            }
        }
        .task(id: url) {
            guard let url else { return }
            if let cached = ImageLoader.shared.cached(url, maxPixelSize: pixelSize) {
                image = cached
                return
            }
            image = await ImageLoader.shared.image(url, maxPixelSize: pixelSize)
        }
    }
}

/// A remote image filling the space it's given, cropped or fitted. For avatars, thumbnails and embeds.
struct RemoteFillImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var maxPixelSize: CGFloat = 1024

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                if image.images != nil {
                    AnimatedImageView(image: image, contentMode: contentMode == .fill ? .scaleAspectFill : .scaleAspectFit)
                } else {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                }
            }
        }
        .clipped()
        .task(id: url) {
            guard let url else { return }
            if let cached = ImageLoader.shared.cached(url, maxPixelSize: maxPixelSize) {
                image = cached
                return
            }
            image = await ImageLoader.shared.image(url, maxPixelSize: maxPixelSize)
        }
    }
}

/// An embedded image in chat: up to 320pt wide at its own aspect ratio.
struct EmbeddedImage: View {
    let url: URL
    let scale: CGFloat

    @State private var image: UIImage?

    var body: some View {
        let maxWidth = 320 * scale
        Group {
            if let image, image.size.width > 0 {
                let width = min(maxWidth, image.size.width)
                AnimatedImageView(image: image)
                    .frame(width: width, height: width * image.size.height / image.size.width)
            } else {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary).frame(width: maxWidth * 0.6, height: maxWidth * 0.4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture { UIApplication.shared.open(url) }
        .task(id: url) {
            image = await ImageLoader.shared.image(url, maxPixelSize: 960)
        }
    }
}

/// UIImageView, which plays animated images; SwiftUI's Image doesn't.
struct AnimatedImageView: UIViewRepresentable {
    let image: UIImage
    var contentMode: UIView.ContentMode = .scaleAspectFit

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = contentMode
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        if view.image !== image {
            view.image = image
            if image.images != nil { view.startAnimating() }
        }
        view.contentMode = contentMode
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: image.size)
    }
}
