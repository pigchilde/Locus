import SwiftUI

struct LocusMark: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 64
        let sy = rect.height / 64
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var path = Path()
        path.move(to: point(32, 11.5))
        path.addCurve(
            to: point(14.5, 30.04),
            control1: point(22.33, 11.5),
            control2: point(14.5, 19.75)
        )
        path.addCurve(
            to: point(32, 54.88),
            control1: point(14.5, 38.16),
            control2: point(20.85, 46.51)
        )
        path.addCurve(
            to: point(49.5, 30.04),
            control1: point(43.15, 46.51),
            control2: point(49.5, 38.16)
        )
        path.addCurve(
            to: point(32, 11.5),
            control1: point(49.5, 19.75),
            control2: point(41.68, 11.5)
        )
        path.closeSubpath()

        path.move(to: point(21.75, 34.88))
        path.addCurve(
            to: point(32, 19.5),
            control1: point(21.75, 26.38),
            control2: point(26.38, 19.5)
        )
        path.addCurve(
            to: point(42.25, 34.88),
            control1: point(37.63, 19.5),
            control2: point(42.25, 26.38)
        )
        return path
    }
}

struct LocusAppIcon: View {
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color.accentColor)
            LocusMark()
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: max(size * 0.059, 1.5),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.17, height: size * 0.17)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }
}
