import SwiftUI

struct FocusTimerView: View {
    let durationSeconds: Int
    let title: String?
    let darkTheme: Bool
    let onExit: () -> Void
    let onComplete: () -> Void

    @State private var elapsed: Double = 0
    @State private var isComplete = false
    @State private var startTime = Date()

    private var remaining: Int {
        max(0, Int(durationSeconds) - Int(elapsed))
    }

    private var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, elapsed / Double(durationSeconds))
    }

    private var timeString: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 40) {
            if let title {
                Text(title)
                    .font(.system(size: 14, weight: .light))
                    .tracking(4)
                    .foregroundStyle(darkTheme ? Color.white.opacity(0.35) : Color.black.opacity(0.45))
            }

            ZStack {
                ProgressRing(
                    progress: progress,
                    isComplete: isComplete,
                    trackColor: darkTheme ? Color.white.opacity(0.08) : Color.black.opacity(0.08),
                    progressColor: darkTheme ? .white : .black
                )

                if isComplete {
                    Text("Session Complete")
                        .font(.system(size: 20, weight: .ultraLight))
                        .tracking(4)
                        .foregroundStyle(darkTheme ? Color.white.opacity(0.9) : Color.black.opacity(0.9))
                } else {
                    Text(timeString)
                        .font(.system(size: 48, weight: .ultraLight))
                        .tracking(0.2)
                        .foregroundStyle(darkTheme ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                        .monospacedDigit()
                }
            }

            if isComplete {
                Button("Start Again") {
                    onExit()
                }
                .font(.system(size: 14, weight: .light))
                .tracking(4)
                .foregroundStyle(darkTheme ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .onAppear {
            startTime = Date()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard !isComplete else { return }
            elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= Double(durationSeconds) {
                elapsed = Double(durationSeconds)
                isComplete = true
                onComplete()
            }
        }
    }
}
