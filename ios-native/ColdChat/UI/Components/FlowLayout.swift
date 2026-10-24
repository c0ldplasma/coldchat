import SwiftUI

/// Lays out words and emotes left to right, wrapping like text. Items in a line are centered vertically, so
/// emotes sit on the text instead of pushing it down.
///
/// Sizes aren't cached: an emote changes size when its image arrives, and the layout has to follow.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        let (lines, _) = arrange(width: width, subviews: subviews)
        let height = lines.reduce(0) { $0 + $1.height } + CGFloat(max(0, lines.count - 1)) * lineSpacing
        let used = lines.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? used, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let (lines, sizes) = arrange(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for line in lines {
            var x = bounds.minX
            for index in line.indices {
                let size = sizes[index]
                subviews[index].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> ([Line], [CGSize]) {
        // A word longer than the line wraps inside itself instead of overflowing.
        let sizes = subviews.map { subview in
            let ideal = subview.sizeThatFits(.unspecified)
            return ideal.width > width ? subview.sizeThatFits(ProposedViewSize(width: width, height: nil)) : ideal
        }
        var lines: [Line] = []
        var current = Line()
        for (index, size) in sizes.enumerated() {
            if !current.indices.isEmpty, current.width + spacing + size.width > width {
                lines.append(current)
                current = Line()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { lines.append(current) }
        return (lines, sizes)
    }
}
