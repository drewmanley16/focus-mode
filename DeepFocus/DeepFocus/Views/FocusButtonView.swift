import SwiftUI

struct FocusButtonView: View {
    @Binding var durationMinutes: Int
    let onActivate: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate * 0.5
                Button(action: onActivate) {
                    Text("Enter Focus")
                        .font(.system(size: 18, weight: .light))
                        .tracking(4)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 208, height: 208)
                        .background(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                .background(Circle().fill(Color.white.opacity(0.03)))
                        )
                        .scaleEffect(1 + sin(phase) * 0.03)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 20) {
                Button {
                    if let idx = FocusManager.durationOptions.firstIndex(of: durationMinutes), idx > 0 {
                        durationMinutes = FocusManager.durationOptions[idx - 1]
                    } else {
                        durationMinutes = FocusManager.durationOptions.last!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(durationLabel)
                    .font(.system(size: 14, weight: .light))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.25))
                    .frame(minWidth: 140, alignment: .center)

                Button {
                    if let idx = FocusManager.durationOptions.firstIndex(of: durationMinutes),
                       idx < FocusManager.durationOptions.count - 1 {
                        durationMinutes = FocusManager.durationOptions[idx + 1]
                    } else {
                        durationMinutes = FocusManager.durationOptions.first!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var durationLabel: String {
        if durationMinutes >= 60 {
            return "\(durationMinutes / 60) hour\(durationMinutes > 60 ? "s" : "") session"
        } else {
            return "\(durationMinutes) minute session"
        }
    }
}
