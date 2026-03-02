import SwiftUI

struct FocusButtonView: View {
    @Binding var durationMinutes: Int
    let pomodoroEnabled: Bool
    let pomodoroPresets: [PomodoroPreset]
    let customTimers: [CustomTimerPreset]
    let onActivateStandard: () -> Void
    let onActivatePomodoro: (PomodoroPreset) -> Void
    let onActivateCustom: (CustomTimerPreset) -> Void
    let onCreateCustom: () -> Void

    @State private var mode: QuickStartMode = .standard
    @State private var pomodoroIndex: Int = 0
    @State private var customIndex: Int = 0

    private enum QuickStartMode: String, CaseIterable {
        case standard = "Focus"
        case pomodoro = "Pomodoro"
        case custom = "Your Timers"
    }

    var body: some View {
        VStack(spacing: 32) {
            Picker("Mode", selection: $mode) {
                ForEach(QuickStartMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)

            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate * 0.5
                Button(action: startSelectedMode) {
                    Text(mainButtonTitle)
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

            controlsView
        }
    }

    @ViewBuilder
    private var controlsView: some View {
        switch mode {
        case .standard:
            durationControl(label: durationLabel, onPrev: standardPrev, onNext: standardNext)
        case .pomodoro:
            if pomodoroEnabled {
                durationControl(label: pomodoroLabel, onPrev: pomodoroPrev, onNext: pomodoroNext)
            } else {
                Text("Enable Pomodoro in Settings")
                    .font(.system(size: 14, weight: .light))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.25))
            }
        case .custom:
            VStack(spacing: 12) {
                if customTimers.isEmpty {
                    Text("No custom timers yet")
                        .font(.system(size: 14, weight: .light))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.25))
                } else {
                    durationControl(label: customTimerLabel, onPrev: customPrev, onNext: customNext)
                }
                Button("Create your own") {
                    onCreateCustom()
                }
                .font(.system(size: 13, weight: .light))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.45))
                .buttonStyle(.plain)
            }
        }
    }

    private func durationControl(label: String, onPrev: @escaping () -> Void, onNext: @escaping () -> Void) -> some View {
        HStack(spacing: 20) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 14, weight: .light))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.25))
                .frame(minWidth: 220, alignment: .center)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var mainButtonTitle: String {
        switch mode {
        case .standard:
            return "Enter Focus"
        case .pomodoro:
            return pomodoroEnabled ? "Start Pomodoro" : "Pomodoro Off"
        case .custom:
            return customTimers.isEmpty ? "Create Timer" : "Start Timer"
        }
    }

    private var pomodoroLabel: String {
        guard !pomodoroPresets.isEmpty else { return "No pomodoro presets" }
        let preset = pomodoroPresets[pomodoroIndex % pomodoroPresets.count]
        return "\(preset.name) • \(preset.focusMinutes)m/\(preset.breakMinutes)m"
    }

    private var customTimerLabel: String {
        guard !customTimers.isEmpty else { return "No custom timers" }
        let timer = customTimers[customIndex % customTimers.count]
        if let breakMinutes = timer.breakMinutes, breakMinutes > 0 {
            return "\(timer.name) • \(timer.focusMinutes)m/\(breakMinutes)m"
        }
        return "\(timer.name) • \(timer.focusMinutes)m"
    }

    private var durationLabel: String {
        if durationMinutes >= 60 {
            return "\(durationMinutes / 60) hour\(durationMinutes > 60 ? "s" : "") session"
        } else {
            return "\(durationMinutes) minute session"
        }
    }

    private func startSelectedMode() {
        switch mode {
        case .standard:
            onActivateStandard()
        case .pomodoro:
            guard pomodoroEnabled, !pomodoroPresets.isEmpty else { return }
            let preset = pomodoroPresets[pomodoroIndex % pomodoroPresets.count]
            onActivatePomodoro(preset)
        case .custom:
            guard !customTimers.isEmpty else {
                onCreateCustom()
                return
            }
            let timer = customTimers[customIndex % customTimers.count]
            onActivateCustom(timer)
        }
    }

    private func standardPrev() {
        if let idx = FocusManager.durationOptions.firstIndex(of: durationMinutes), idx > 0 {
            durationMinutes = FocusManager.durationOptions[idx - 1]
        } else {
            durationMinutes = FocusManager.durationOptions.last ?? durationMinutes
        }
    }

    private func standardNext() {
        if let idx = FocusManager.durationOptions.firstIndex(of: durationMinutes),
           idx < FocusManager.durationOptions.count - 1 {
            durationMinutes = FocusManager.durationOptions[idx + 1]
        } else {
            durationMinutes = FocusManager.durationOptions.first ?? durationMinutes
        }
    }

    private func pomodoroPrev() {
        guard !pomodoroPresets.isEmpty else { return }
        pomodoroIndex = (pomodoroIndex - 1 + pomodoroPresets.count) % pomodoroPresets.count
    }

    private func pomodoroNext() {
        guard !pomodoroPresets.isEmpty else { return }
        pomodoroIndex = (pomodoroIndex + 1) % pomodoroPresets.count
    }

    private func customPrev() {
        guard !customTimers.isEmpty else { return }
        customIndex = (customIndex - 1 + customTimers.count) % customTimers.count
    }

    private func customNext() {
        guard !customTimers.isEmpty else { return }
        customIndex = (customIndex + 1) % customTimers.count
    }
}
