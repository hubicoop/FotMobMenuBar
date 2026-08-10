import AppKit
import SwiftUI

@MainActor
enum FotMobLogoImage {
    static let menuBar: NSImage = {
        let renderer = ImageRenderer(
            content: FotMobLogoView(original: false)
                .frame(width: 18, height: 18)
        )
        let image = renderer.nsImage
            ?? NSImage(systemSymbolName: "sportscourt", accessibilityDescription: "FotMob")!
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}

struct FotMobLogoView: View {
    let original: Bool

    var body: some View {
        ZStack {
            if original {
                Color(red: 0, green: 0.596, blue: 0.373)
            }
            FotMobMark()
                .fill(original ? .white : .primary)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: original ? 0.2 : 0, style: .continuous))
        .accessibilityLabel("FotMob")
    }
}

private struct FotMobMark: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x / 1024, y: rect.minY + rect.height * y / 1024)
        }

        var path = Path()

        path.move(to: point(386.904, 912.947))
        path.addLine(to: point(236.573, 912.947))
        path.addLine(to: point(236.573, 786.491))
        path.addLine(to: point(386.905, 705.578))
        path.closeSubpath()

        path.move(to: point(0.054, 869.606))
        path.addLine(to: point(0.054, 756.787))
        path.addLine(to: point(446.348, 582.126))
        path.addCurve(
            to: point(465.889, 618.666),
            control1: point(451.025, 595.203),
            control2: point(457.61, 607.516)
        )
        path.closeSubpath()

        path.move(to: point(0.003, 715.093))
        path.addLine(to: point(0.003, 601.472))
        path.addLine(to: point(443.916, 494.387))
        path.addCurve(
            to: point(438.429, 542.899),
            control1: point(439.128, 510.084),
            control2: point(437.268, 526.529)
        )
        path.addLine(to: point(0.054, 715.093))
        path.closeSubpath()

        path.addEllipse(in: CGRect(
            x: rect.minX + rect.width * 477.127 / 1024,
            y: rect.minY + rect.height * 432.263 / 1024,
            width: rect.width * 204.818 / 1024,
            height: rect.height * 204.818 / 1024
        ))

        path.move(to: point(236.573, 504.149))
        path.addLine(to: point(236.573, 155.247))
        path.addCurve(
            to: point(280.887, 110.933),
            control1: point(236.586, 143.498),
            control2: point(269.138, 110.946)
        )
        path.addLine(to: point(811.659, 110.933))
        path.addCurve(
            to: point(855.973, 155.247),
            control1: point(823.407, 110.948),
            control2: point(855.958, 143.499)
        )
        path.addLine(to: point(855.973, 259.78))
        path.addLine(to: point(386.904, 259.78))
        path.addLine(to: point(386.904, 467.951))
        path.addLine(to: point(236.573, 504.149))
        path.closeSubpath()

        return path
    }
}
