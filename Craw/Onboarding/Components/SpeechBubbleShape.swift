import SwiftUI

struct SpeechBubbleShape: Shape {
    static let tailHeight: CGFloat = 14
    static let tailWidth: CGFloat = 28
    static let cornerRadius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bubble = CGRect(
            x: rect.minX,
            y: rect.minY + Self.tailHeight,
            width: rect.width,
            height: rect.height - Self.tailHeight
        )
        let radius = Self.cornerRadius
        let tailCenterX = bubble.midX - 32
        let tailLeftX = tailCenterX - Self.tailWidth / 2
        let tailRightX = tailCenterX + Self.tailWidth / 2

        path.move(to: CGPoint(x: bubble.minX + radius, y: bubble.minY))
        path.addLine(to: CGPoint(x: tailLeftX, y: bubble.minY))
        path.addLine(to: CGPoint(x: tailCenterX - 6, y: rect.minY))
        path.addLine(to: CGPoint(x: tailRightX, y: bubble.minY))
        path.addLine(to: CGPoint(x: bubble.maxX - radius, y: bubble.minY))
        path.addArc(
            center: CGPoint(x: bubble.maxX - radius, y: bubble.minY + radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: bubble.maxX, y: bubble.maxY - radius))
        path.addArc(
            center: CGPoint(x: bubble.maxX - radius, y: bubble.maxY - radius),
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: bubble.minX + radius, y: bubble.maxY))
        path.addArc(
            center: CGPoint(x: bubble.minX + radius, y: bubble.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: bubble.minX, y: bubble.minY + radius))
        path.addArc(
            center: CGPoint(x: bubble.minX + radius, y: bubble.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct MascotSpeechBubble: View {
    let text: String
    var font: Font = Theme.Typography.displaySm
    var maxWidth: CGFloat = 340

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Theme.Palette.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.base + SpeechBubbleShape.tailHeight)
            .padding(.bottom, Theme.Spacing.base)
            .frame(maxWidth: maxWidth)
            .background {
                SpeechBubbleShape()
                    .fill(Theme.Palette.surfaceCard)
                    .overlay(
                        SpeechBubbleShape()
                            .stroke(Theme.Palette.ink, lineWidth: 2.5)
                    )
            }
    }
}

#Preview {
    VStack(spacing: 24) {
        MascotSpeechBubble(text: "Hello there!")
        MascotSpeechBubble(text: "Required to save your progress")
    }
    .padding()
}
