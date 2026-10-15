import SwiftUI

struct ProgressRing: View {
    let current: Int
    let goal: Int
    let label: String

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ScaledMetric(relativeTo: .title2)
    private var ringSize: CGFloat = 100

    private var progress: Double {
        guard goal > 0 else {
            return 0
        }

        return min(
            max(Double(current) / Double(goal), 0),
            1
        )
    }

    private var percentage: Int {
        Int((progress * 100).rounded())
    }

    var body: some View {
        ZStack {
            // The background track.
            Circle()
                .stroke(
                    Brand.accent.opacity(0.15),
                    lineWidth: 9
                )

            // The filled portion starts at the top.
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Brand.accent,
                    style: StrokeStyle(
                        lineWidth: 9,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 0.4),
                    value: progress
                )

            Text("\(percentage)%")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(
            width: ringSize,
            height: ringSize
        )
        .padding(5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(
            Text(
                "\(max(current, 0)) of \(max(goal, 0)), \(percentage) percent"
            )
        )
    }
}