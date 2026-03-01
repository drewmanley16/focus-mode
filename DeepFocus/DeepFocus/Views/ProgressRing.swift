import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let isComplete: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 2)
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.white.opacity(isComplete ? 0.9 : 0.35),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
    }
}
