import SwiftUI

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager
    @StateObject private var audioEngine = AmbientAudioEngine()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AudioReactiveBackground(audioLevel: audioEngine.audioLevel, active: focusManager.isFocusing)

            VStack {
                Spacer()
                if focusManager.state == .idle {
                    FocusButtonView(durationMinutes: Binding(
                        get: { focusManager.durationMinutes },
                        set: { focusManager.durationMinutes = $0 }
                    )) {
                        focusManager.enterFocus()
                    }
                } else {
                    FocusTimerView(
                        durationSeconds: focusManager.durationMinutes * 60,
                        onExit: { focusManager.exitFocus() },
                        onComplete: {
                            playCompletionSound()
                            focusManager.complete()
                        }
                    )
                }
                Spacer()
            }

            if focusManager.isFocusing && !focusManager.isWindowVisible {
                Color.black.opacity(0.8)
                    .overlay(
                        Text("Welcome back. Stay focused.")
                            .font(.system(size: 18, weight: .ultraLight))
                            .tracking(4)
                            .foregroundStyle(Color.white.opacity(0.4))
                    )
                    .allowsHitTesting(false)
            }

            if focusManager.state == .idle {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            focusManager.enterFocus()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("Start")
                                    .font(.system(size: 12, weight: .light))
                                    .tracking(4)
                            }
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    .background(Capsule().fill(Color.white.opacity(0.04)))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                    }
                    Spacer()
                }
            }

            if focusManager.state == .focusing {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Exit") {
                            focusManager.exitFocus()
                        }
                        .font(.system(size: 12, weight: .light))
                        .tracking(4)
                        .foregroundStyle(Color.white.opacity(0.15))
                        .buttonStyle(.plain)
                        .padding(32)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopFocus)) { _ in
            // Audio temporarily disabled while isolating session start behavior.
        }
    }

    private func playCompletionSound() {
        CompletionSound.play()
    }
}
