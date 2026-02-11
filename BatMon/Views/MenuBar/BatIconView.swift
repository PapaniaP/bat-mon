import SwiftUI

/// Custom bat-shaped icon for the menu bar when disconnected
struct BatIconView: View {
    let fillColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat

    init(fillColor: Color, borderColor: Color? = nil, borderWidth: CGFloat = 0.7) {
        self.fillColor = fillColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    var body: some View {
        // Inset the shape slightly to prevent border clipping at edges
        let inset = borderColor != nil ? borderWidth / 2 : 0

        BatShape()
            .fill(fillColor)
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        BatShape()
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
            .padding(inset)
            .frame(width: 20, height: 14)
    }
}

/// The bat silhouette as a SwiftUI Shape
struct BatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Scale factors to fit the shape in the rect
        let sx = w / 22.0
        let sy = h / 14.0

        // Start at top center (head area)
        path.move(to: CGPoint(x: 11 * sx, y: 1.5 * sy))

        // Left wing - outer edge
        path.addCurve(
            to: CGPoint(x: 7 * sx, y: 0.5 * sy),
            control1: CGPoint(x: 9 * sx, y: 0 * sy),
            control2: CGPoint(x: 7 * sx, y: 0.5 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 1.5 * sx, y: 5 * sy),
            control1: CGPoint(x: 5 * sx, y: 1 * sy),
            control2: CGPoint(x: 3 * sx, y: 3 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 0 * sx, y: 9 * sy),
            control1: CGPoint(x: 0.5 * sx, y: 6.5 * sy),
            control2: CGPoint(x: 0 * sx, y: 8 * sy)
        )

        // Left wing tip curl
        path.addCurve(
            to: CGPoint(x: 1 * sx, y: 9.5 * sy),
            control1: CGPoint(x: 0 * sx, y: 9.8 * sy),
            control2: CGPoint(x: 0.5 * sx, y: 10 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 4.5 * sx, y: 7.5 * sy),
            control1: CGPoint(x: 2 * sx, y: 8.5 * sy),
            control2: CGPoint(x: 3.5 * sx, y: 7.5 * sy)
        )

        // Left inner wing
        path.addCurve(
            to: CGPoint(x: 5.7 * sx, y: 8.8 * sy),
            control1: CGPoint(x: 5.2 * sx, y: 7.5 * sy),
            control2: CGPoint(x: 5.5 * sx, y: 8 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 6.2 * sx, y: 12.2 * sy),
            control1: CGPoint(x: 6 * sx, y: 9.8 * sy),
            control2: CGPoint(x: 5.7 * sx, y: 11 * sy)
        )

        // Left foot
        path.addCurve(
            to: CGPoint(x: 8 * sx, y: 13.5 * sy),
            control1: CGPoint(x: 6.5 * sx, y: 13 * sy),
            control2: CGPoint(x: 7.2 * sx, y: 13.5 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 9.2 * sx, y: 11.8 * sy),
            control1: CGPoint(x: 8.7 * sx, y: 13.5 * sy),
            control2: CGPoint(x: 9.2 * sx, y: 13 * sy)
        )

        // Center body
        path.addCurve(
            to: CGPoint(x: 11 * sx, y: 9 * sy),
            control1: CGPoint(x: 9.2 * sx, y: 10.5 * sy),
            control2: CGPoint(x: 9.8 * sx, y: 9 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 12.8 * sx, y: 11.8 * sy),
            control1: CGPoint(x: 12.2 * sx, y: 9 * sy),
            control2: CGPoint(x: 12.8 * sx, y: 10.5 * sy)
        )

        // Right foot
        path.addCurve(
            to: CGPoint(x: 14 * sx, y: 13.5 * sy),
            control1: CGPoint(x: 12.8 * sx, y: 13 * sy),
            control2: CGPoint(x: 13.3 * sx, y: 13.5 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 15.8 * sx, y: 12.2 * sy),
            control1: CGPoint(x: 14.8 * sx, y: 13.5 * sy),
            control2: CGPoint(x: 15.5 * sx, y: 13 * sy)
        )

        // Right inner wing
        path.addCurve(
            to: CGPoint(x: 16.3 * sx, y: 8.8 * sy),
            control1: CGPoint(x: 16.3 * sx, y: 11 * sy),
            control2: CGPoint(x: 16 * sx, y: 9.8 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 17.5 * sx, y: 7.5 * sy),
            control1: CGPoint(x: 16.5 * sx, y: 8 * sy),
            control2: CGPoint(x: 16.8 * sx, y: 7.5 * sy)
        )

        // Right wing tip curl
        path.addCurve(
            to: CGPoint(x: 21 * sx, y: 9.5 * sy),
            control1: CGPoint(x: 18.5 * sx, y: 7.5 * sy),
            control2: CGPoint(x: 20 * sx, y: 8.5 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 22 * sx, y: 9 * sy),
            control1: CGPoint(x: 21.5 * sx, y: 10 * sy),
            control2: CGPoint(x: 22 * sx, y: 9.8 * sy)
        )

        // Right wing - outer edge
        path.addCurve(
            to: CGPoint(x: 20.5 * sx, y: 5 * sy),
            control1: CGPoint(x: 22 * sx, y: 8 * sy),
            control2: CGPoint(x: 21.5 * sx, y: 6.5 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 15 * sx, y: 0.5 * sy),
            control1: CGPoint(x: 19 * sx, y: 3 * sy),
            control2: CGPoint(x: 17 * sx, y: 1 * sy)
        )

        // Back to top center
        path.addCurve(
            to: CGPoint(x: 11 * sx, y: 1.5 * sy),
            control1: CGPoint(x: 13 * sx, y: 0 * sy),
            control2: CGPoint(x: 11 * sx, y: 1.5 * sy)
        )

        path.closeSubpath()

        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        // White fill, no border
        BatIconView(fillColor: .white)
            .background(Color.black)

        // Black fill, red border
        BatIconView(fillColor: .black, borderColor: .red, borderWidth: 1)
            .background(Color.white)

        // Blue fill, yellow border
        BatIconView(fillColor: .blue, borderColor: .yellow, borderWidth: 1.5)
            .background(Color.gray)
    }
    .padding()
}
