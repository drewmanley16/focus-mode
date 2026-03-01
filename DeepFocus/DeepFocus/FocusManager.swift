import Foundation
import SwiftUI
import AppKit

enum FocusState {
    case idle
    case focusing
    case complete
}

@MainActor
final class FocusManager: ObservableObject {
    @Published var state: FocusState = .idle
    @Published var durationMinutes: Int = 45
    @Published var isWindowVisible: Bool = true

    static let durationOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]

    var isFocusing: Bool {
        state == .focusing || state == .complete
    }

    func enterFocus(minutes: Int? = nil) {
        if let m = minutes {
            durationMinutes = m
        }
        state = .focusing
        NotificationCenter.default.post(name: .focusStateChanged, object: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .enterFullscreen, object: nil)
        }
    }

    func exitFocus() {
        state = .idle
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
}
