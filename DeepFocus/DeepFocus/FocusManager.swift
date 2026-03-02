import Foundation
import SwiftUI
import AppKit

enum FocusState {
    case idle
    case deepStart
    case focusing
    case breakTime
    case complete
}

struct PomodoroPreset: Equatable {
    let name: String
    let focusMinutes: Int
    let breakMinutes: Int
}

struct CustomTimerPreset: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var focusMinutes: Int
    var breakMinutes: Int?

    var isPomodoro: Bool {
        (breakMinutes ?? 0) > 0
    }
}

enum SessionMode: Equatable {
    case standard
    case pomodoro(PomodoroPreset)
}

@MainActor
final class FocusManager: ObservableObject {
    @Published var state: FocusState = .idle
    @Published var durationMinutes: Int = 45
    @Published var isWindowVisible: Bool = true
    @Published var cycleCount: Int = 0
    @Published var currentPhaseDurationSeconds: Int = 0
    @Published var currentMode: SessionMode = .standard
    @Published var pomodoroEnabled: Bool = UserDefaults.standard.bool(forKey: "settings.pomodoro.enabled") {
        didSet { UserDefaults.standard.set(pomodoroEnabled, forKey: "settings.pomodoro.enabled") }
    }
    @Published var deepStartEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "settings.deepstart.enabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "settings.deepstart.enabled")
    }() {
        didSet { UserDefaults.standard.set(deepStartEnabled, forKey: "settings.deepstart.enabled") }
    }
    @Published var deepStartDurationSeconds: Int = {
        let saved = UserDefaults.standard.integer(forKey: "settings.deepstart.seconds")
        return saved > 0 ? saved : 20
    }() {
        didSet { UserDefaults.standard.set(deepStartDurationSeconds, forKey: "settings.deepstart.seconds") }
    }
    @Published var customTimers: [CustomTimerPreset] = FocusManager.loadCustomTimers() {
        didSet {
            FocusManager.saveCustomTimers(customTimers)
            NotificationCenter.default.post(name: .focusStateChanged, object: nil)
        }
    }

    static let durationOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
    static let pomodoroPresets: [PomodoroPreset] = [
        PomodoroPreset(name: "Classic 25/5", focusMinutes: 25, breakMinutes: 5),
        PomodoroPreset(name: "Flow 50/10", focusMinutes: 50, breakMinutes: 10),
        PomodoroPreset(name: "Ultradian 52/17", focusMinutes: 52, breakMinutes: 17)
    ]
    private static let customTimersKey = "settings.customtimers.items"

    var isFocusing: Bool {
        state != .idle
    }

    var isBreakPhase: Bool {
        state == .breakTime
    }

    var statusTitle: String {
        switch state {
        case .idle:
            return "Idle"
        case .deepStart:
            return "Deep Start…"
        case .focusing:
            return "Focusing…"
        case .breakTime:
            return "Break…"
        case .complete:
            return "Session Complete"
        }
    }

    func enterFocus(minutes: Int? = nil) {
        enterStandardFocus(minutes: minutes)
    }

    func enterStandardFocus(minutes: Int? = nil) {
        if let m = minutes {
            durationMinutes = m
        }
        currentMode = .standard
        cycleCount = 0
        if deepStartEnabled {
            state = .deepStart
            currentPhaseDurationSeconds = max(5, deepStartDurationSeconds)
        } else {
            state = .focusing
            currentPhaseDurationSeconds = durationMinutes * 60
        }
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .enterFullscreen, object: nil)
        }
    }

    func enterPomodoro(_ preset: PomodoroPreset) {
        guard pomodoroEnabled else { return }
        currentMode = .pomodoro(preset)
        cycleCount = 1
        if deepStartEnabled {
            state = .deepStart
            currentPhaseDurationSeconds = max(5, deepStartDurationSeconds)
        } else {
            state = .focusing
            currentPhaseDurationSeconds = preset.focusMinutes * 60
        }
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .enterFullscreen, object: nil)
        }
    }

    func startCustomTimer(_ timer: CustomTimerPreset) {
        if let breakMinutes = timer.breakMinutes, breakMinutes > 0 {
            enterPomodoro(PomodoroPreset(name: timer.name, focusMinutes: timer.focusMinutes, breakMinutes: breakMinutes))
        } else {
            enterStandardFocus(minutes: timer.focusMinutes)
        }
    }

    func addCustomTimer(name: String, focusMinutes: Int, breakMinutes: Int?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = trimmed.isEmpty ? "My Timer" : trimmed
        let timer = CustomTimerPreset(
            id: UUID(),
            name: safeName,
            focusMinutes: max(1, focusMinutes),
            breakMinutes: {
                guard let breakMinutes, breakMinutes > 0 else { return nil }
                return breakMinutes
            }()
        )
        customTimers.append(timer)
    }

    func deleteCustomTimer(id: UUID) {
        customTimers.removeAll { $0.id == id }
    }

    func updateCustomTimer(_ timer: CustomTimerPreset) {
        guard let idx = customTimers.firstIndex(where: { $0.id == timer.id }) else { return }
        customTimers[idx] = timer
    }

    func moveCustomTimers(from source: IndexSet, to destination: Int) {
        customTimers.move(fromOffsets: source, toOffset: destination)
    }

    func beginFocusPhase() {
        switch currentMode {
        case .standard:
            state = .focusing
            currentPhaseDurationSeconds = durationMinutes * 60
        case .pomodoro(let preset):
            if cycleCount == 0 {
                cycleCount = 1
            }
            state = .focusing
            currentPhaseDurationSeconds = preset.focusMinutes * 60
        }
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
    }

    func advanceAfterTimerCompletion() {
        switch state {
        case .deepStart:
            beginFocusPhase()
        case .focusing:
            switch currentMode {
            case .standard:
                complete()
            case .pomodoro(let preset):
                state = .breakTime
                currentPhaseDurationSeconds = preset.breakMinutes * 60
                NotificationCenter.default.post(name: .focusStateChanged, object: nil)
            }
        case .breakTime:
            cycleCount += 1
            beginFocusPhase()
        case .idle, .complete:
            break
        }
    }

    func skipBreakIfNeeded() {
        guard state == .breakTime else { return }
        cycleCount += 1
        beginFocusPhase()
    }

    func startFromShortcut() {
        guard state == .idle else { return }
        enterStandardFocus()
    }

    func stopFromShortcut() {
        guard state != .idle else { return }
        exitFocus()
    }

    func exitFocus() {
        state = .idle
        currentPhaseDurationSeconds = 0
        cycleCount = 0
        currentMode = .standard
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .exitFullscreen, object: nil)
        }
    }

    func complete() {
        state = .complete
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
    }

    func prepareForQuit() {
        state = .idle
    }

    private static func loadCustomTimers() -> [CustomTimerPreset] {
        guard let data = UserDefaults.standard.data(forKey: customTimersKey),
              let decoded = try? JSONDecoder().decode([CustomTimerPreset].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func saveCustomTimers(_ timers: [CustomTimerPreset]) {
        guard let data = try? JSONEncoder().encode(timers) else { return }
        UserDefaults.standard.set(data, forKey: customTimersKey)
    }
}
