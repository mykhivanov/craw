import SwiftUI

struct StatsTrendCard: View {
    let title: String
    let subtitle: String
    let points: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(title)
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                Spacer()
                Text(subtitle)
                    .font(Theme.Typography.badge)
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }

            if hasData {
                StatsSparkline(points: points)
                    .frame(height: 120)
            } else {
                Text("Not enough data yet")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.mutedSoft)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var hasData: Bool {
        points.contains { $0.value != nil }
    }
}

struct StatsSparkline: View {
    let points: [TrendPoint]

    var body: some View {
        GeometryReader { proxy in
            let plottable = points.compactMap { point -> (Date, Double)? in
                guard let value = point.value else { return nil }
                return (point.at, value)
            }
            let values = plottable.map(\.1)
            let minV = values.min() ?? 0
            let maxV = values.max() ?? 1
            let range = max(1e-6, maxV - minV)

            let coords: [CGPoint] = plottable.enumerated().map { index, pair in
                let x: CGFloat = plottable.count <= 1
                    ? proxy.size.width / 2
                    : CGFloat(index) / CGFloat(plottable.count - 1) * proxy.size.width
                let y = proxy.size.height - CGFloat((pair.1 - minV) / range) * proxy.size.height
                return CGPoint(x: x, y: y)
            }

            ZStack {
                Path { path in
                    guard let first = coords.first else { return }
                    path.move(to: first)
                    for point in coords.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    Theme.Palette.rausch,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                ForEach(coords.indices, id: \.self) { index in
                    Circle()
                        .fill(Theme.Palette.rausch)
                        .frame(width: 5, height: 5)
                        .position(coords[index])
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
