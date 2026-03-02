import SwiftUI

struct ContentView: View {
    @EnvironmentObject var focusManager: FocusManager
    @StateObject private var audioEngine = AmbientAudioEngine()
    @State private var showSettings = false
    @State private var showCreateTimer = false

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            AudioReactiveBackground(audioLevel: audioEngine.audioLevel, active: focusManager.isFocusing)

            VStack {
                Spacer()
                if focusManager.state == .idle {
                    FocusButtonView(
                        durationMinutes: Binding(
                            get: { focusManager.durationMinutes },
                            set: { focusManager.durationMinutes = $0 }
                        ),
                        pomodoroEnabled: focusManager.pomodoroEnabled,
                        pomodoroPresets: FocusManager.pomodoroPresets,
                        customTimers: focusManager.customTimers,
                        onActivateStandard: { focusManager.enterStandardFocus() },
                        onActivatePomodoro: { preset in focusManager.enterPomodoro(preset) },
                        onActivateCustom: { timer in focusManager.startCustomTimer(timer) },
                        onCreateCustom: { showCreateTimer = true }
                    )
                } else if focusManager.state == .deepStart {
                    DeepStartCountdownView(
                        durationSeconds: focusManager.currentPhaseDurationSeconds,
                        darkTheme: true,
                        onComplete: { focusManager.advanceAfterTimerCompletion() }
                    )
                } else if focusManager.state == .complete {
                    CompletionView(onDone: { focusManager.exitFocus() })
                } else {
                    FocusTimerView(
                        durationSeconds: focusManager.currentPhaseDurationSeconds,
                        title: sessionTitle,
                        darkTheme: !focusManager.isBreakPhase,
                        onExit: { focusManager.exitFocus() },
                        onComplete: {
                            if shouldPlayCompletion {
                                playCompletionSound()
                            }
                            focusManager.advanceAfterTimerCompletion()
                        }
                    )
                    .id("\(focusManager.state)-\(focusManager.cycleCount)-\(focusManager.currentPhaseDurationSeconds)")
                }
                Spacer()
            }

            if focusManager.isFocusing && !focusManager.isWindowVisible {
                overlayColor.opacity(0.8)
                    .overlay(
                        Text("Welcome back. Stay focused.")
                            .font(.system(size: 18, weight: .ultraLight))
                            .tracking(4)
                            .foregroundStyle(overlayTextColor.opacity(0.4))
                    )
                    .allowsHitTesting(false)
            }

            if focusManager.state == .idle {
                VStack {
                    HStack {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(16)

                        Spacer()

                        Button {
                            focusManager.enterStandardFocus()
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
        .sheet(isPresented: $showSettings) {
            SettingsView(
                pomodoroEnabled: Binding(
                    get: { focusManager.pomodoroEnabled },
                    set: { focusManager.pomodoroEnabled = $0 }
                ),
                deepStartEnabled: Binding(
                    get: { focusManager.deepStartEnabled },
                    set: { focusManager.deepStartEnabled = $0 }
                ),
                deepStartDurationSeconds: Binding(
                    get: { focusManager.deepStartDurationSeconds },
                    set: { focusManager.deepStartDurationSeconds = $0 }
                ),
                customTimers: Binding(
                    get: { focusManager.customTimers },
                    set: { focusManager.customTimers = $0 }
                )
            )
            .frame(minWidth: 520, minHeight: 420)
        }
        .sheet(isPresented: $showCreateTimer) {
            CreateCustomTimerView { name, focusMinutes, breakMinutes in
                focusManager.addCustomTimer(name: name, focusMinutes: focusMinutes, breakMinutes: breakMinutes)
                showCreateTimer = false
            }
            .frame(minWidth: 380, minHeight: 300)
        }
    }

    private func playCompletionSound() {
        CompletionSound.play()
    }

    private var backgroundColor: Color {
        focusManager.isBreakPhase ? .white : .black
    }

    private var overlayColor: Color {
        focusManager.isBreakPhase ? .white : .black
    }

    private var overlayTextColor: Color {
        focusManager.isBreakPhase ? .black : .white
    }

    private var sessionTitle: String {
        switch focusManager.state {
        case .breakTime:
            return "POMODORO BREAK"
        case .focusing:
            switch focusManager.currentMode {
            case .standard:
                return "FOCUS SESSION"
            case .pomodoro:
                return "POMODORO FOCUS  •  CYCLE \(max(1, focusManager.cycleCount))"
            }
        case .deepStart:
            return "DEEP START"
        case .idle, .complete:
            return "FOCUS SESSION"
        }
    }

    private var shouldPlayCompletion: Bool {
        switch focusManager.currentMode {
        case .standard:
            return focusManager.state == .focusing
        case .pomodoro:
            return false
        }
    }
}

private struct DeepStartCountdownView: View {
    let durationSeconds: Int
    let darkTheme: Bool
    let onComplete: () -> Void

    @State private var startTime = Date()
    @State private var elapsed: Double = 0

    private var remaining: Int {
        max(0, Int(ceil(Double(durationSeconds) - elapsed)))
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Deep Start")
                .font(.system(size: 16, weight: .light))
                .tracking(6)
                .foregroundStyle(darkTheme ? Color.white.opacity(0.45) : Color.black.opacity(0.45))

            Text("\(remaining)")
                .font(.system(size: 84, weight: .ultraLight))
                .monospacedDigit()
                .foregroundStyle(darkTheme ? Color.white.opacity(0.9) : Color.black.opacity(0.9))

            Text("Breathe in. Set your intention.")
                .font(.system(size: 14, weight: .light))
                .tracking(1.5)
                .foregroundStyle(darkTheme ? Color.white.opacity(0.35) : Color.black.opacity(0.35))
        }
        .onAppear {
            startTime = Date()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= Double(durationSeconds) {
                onComplete()
            }
        }
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var pomodoroEnabled: Bool
    @Binding var deepStartEnabled: Bool
    @Binding var deepStartDurationSeconds: Int
    @Binding var customTimers: [CustomTimerPreset]
    @State private var timerBeingEdited: CustomTimerPreset?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 20, weight: .light))
                .tracking(2)

            GroupBox("Session Options") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Pomodoro", isOn: $pomodoroEnabled)
                        .toggleStyle(.switch)

                    Toggle("Enable Deep Start", isOn: $deepStartEnabled)
                        .toggleStyle(.switch)

                    HStack {
                        Text("Deep Start Duration")
                        Spacer()
                        Stepper(value: $deepStartDurationSeconds, in: 5...60, step: 5) {
                            Text("\(deepStartDurationSeconds)s")
                                .frame(minWidth: 56, alignment: .trailing)
                        }
                        .disabled(!deepStartEnabled)
                    }
                }
            }

            GroupBox("Manage Timers") {
                VStack(alignment: .leading, spacing: 10) {
                    if customTimers.isEmpty {
                        Text("No custom timers yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        List {
                            ForEach(Array(customTimers.enumerated()), id: \.element.id) { index, timer in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(timer.name)
                                        if let breakMinutes = timer.breakMinutes, breakMinutes > 0 {
                                            Text("\(timer.focusMinutes)m focus • \(breakMinutes)m break")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("\(timer.focusMinutes)m focus only")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        guard index > 0 else { return }
                                        customTimers.swapAt(index, index - 1)
                                    } label: {
                                        Image(systemName: "chevron.up")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(index == 0)
                                    Button {
                                        guard index < customTimers.count - 1 else { return }
                                        customTimers.swapAt(index, index + 1)
                                    } label: {
                                        Image(systemName: "chevron.down")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(index >= customTimers.count - 1)
                                    Button("Edit") {
                                        timerBeingEdited = timer
                                    }
                                    .buttonStyle(.borderless)
                                    Button("Delete", role: .destructive) {
                                        customTimers.removeAll { $0.id == timer.id }
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                        .frame(minHeight: 160)
                    }
                    HStack {
                        Text("Use arrows to reorder timers.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
        }
        .padding(20)
        .sheet(item: $timerBeingEdited) { timer in
            EditCustomTimerView(timer: timer) { updated in
                if let idx = customTimers.firstIndex(where: { $0.id == updated.id }) {
                    customTimers[idx] = updated
                }
                timerBeingEdited = nil
            }
            .frame(minWidth: 380, minHeight: 300)
        }
    }
}

private struct CompletionView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Session Complete")
                .font(.system(size: 28, weight: .ultraLight))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.9))

            Button("Start Again") {
                onDone()
            }
            .font(.system(size: 14, weight: .light))
            .tracking(4)
            .foregroundStyle(Color.white.opacity(0.35))
            .buttonStyle(.plain)
        }
    }
}

private struct CreateCustomTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var focusMinutes = 30
    @State private var isPomodoro = false
    @State private var breakMinutes = 5
    let onSave: (String, Int, Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create Your Timer")
                .font(.system(size: 20, weight: .light))
                .tracking(2)

            TextField("Timer name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Focus duration")
                Spacer()
                Stepper(value: $focusMinutes, in: 1...240, step: 1) {
                    Text("\(focusMinutes) min")
                        .frame(minWidth: 74, alignment: .trailing)
                }
            }

            Toggle("Pomodoro style (focus + break)", isOn: $isPomodoro)
                .toggleStyle(.switch)

            if isPomodoro {
                HStack {
                    Text("Break duration")
                    Spacer()
                    Stepper(value: $breakMinutes, in: 1...90, step: 1) {
                        Text("\(breakMinutes) min")
                            .frame(minWidth: 74, alignment: .trailing)
                    }
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save Timer") {
                    onSave(name, focusMinutes, isPomodoro ? breakMinutes : nil)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}

private struct EditCustomTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var focusMinutes: Int
    @State private var isPomodoro: Bool
    @State private var breakMinutes: Int
    let timerID: UUID
    let onSave: (CustomTimerPreset) -> Void

    init(timer: CustomTimerPreset, onSave: @escaping (CustomTimerPreset) -> Void) {
        _name = State(initialValue: timer.name)
        _focusMinutes = State(initialValue: timer.focusMinutes)
        _isPomodoro = State(initialValue: (timer.breakMinutes ?? 0) > 0)
        _breakMinutes = State(initialValue: timer.breakMinutes ?? 5)
        self.timerID = timer.id
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Timer")
                .font(.system(size: 20, weight: .light))
                .tracking(2)

            TextField("Timer name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Focus duration")
                Spacer()
                Stepper(value: $focusMinutes, in: 1...240, step: 1) {
                    Text("\(focusMinutes) min")
                        .frame(minWidth: 74, alignment: .trailing)
                }
            }

            Toggle("Pomodoro style (focus + break)", isOn: $isPomodoro)
                .toggleStyle(.switch)

            if isPomodoro {
                HStack {
                    Text("Break duration")
                    Spacer()
                    Stepper(value: $breakMinutes, in: 1...90, step: 1) {
                        Text("\(breakMinutes) min")
                            .frame(minWidth: 74, alignment: .trailing)
                    }
                }
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save Changes") {
                    let updated = CustomTimerPreset(
                        id: timerID,
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Timer" : name,
                        focusMinutes: max(1, focusMinutes),
                        breakMinutes: isPomodoro ? max(1, breakMinutes) : nil
                    )
                    onSave(updated)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }
}
