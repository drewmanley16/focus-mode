import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let isComplete: Bool
    let trackColor: Color
    let progressColor: Color

    init(progress: Double, isComplete: Bool, trackColor: Color = Color.white.opacity(0.08), progressColor: Color = .white) {
        self.progress = progress
        self.isComplete = isComplete
        self.trackColor = trackColor
        self.progressColor = progressColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: 2)
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor.opacity(isComplete ? 0.9 : 0.35),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
    }
}
