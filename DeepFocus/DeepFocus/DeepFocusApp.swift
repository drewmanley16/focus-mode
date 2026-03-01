import SwiftUI

@main
struct DeepFocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.focusManager)
                .frame(minWidth: 600, minHeight: 500)
                .background(WindowAccessor(focusManager: appDelegate.focusManager))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
        .defaultSize(width: 600, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// Tracks window focus for the "Welcome back" overlay
struct WindowAccessor: NSViewRepresentable {
    @ObservedObject var focusManager: FocusManager

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.observeWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.observedWindow == nil, let window = nsView.window {
            context.coordinator.observeWindow(window)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(focusManager: focusManager)
    }

    class Coordinator: NSObject, NSWindowDelegate {
        let focusManager: FocusManager
        var observedWindow: NSWindow?
        private var isObservingNotifications = false
        private var cursorHidden = false
        private var mouseActivityMonitor: Any?
        private var savedPresentationOptions: NSApplication.PresentationOptions?

        init(focusManager: FocusManager) {
            self.focusManager = focusManager
        }

        deinit {
            if let mouseActivityMonitor {
                NSEvent.removeMonitor(mouseActivityMonitor)
            }
            restoreNormalPresentationIfNeeded()
            NotificationCenter.default.removeObserver(self)
        }

        func observeWindow(_ window: NSWindow) {
            guard observedWindow != window else { return }
            observedWindow = window
            window.delegate = self
            window.styleMask.insert(.resizable)
            window.collectionBehavior.insert(.fullScreenPrimary)
            window.acceptsMouseMovedEvents = true
            installMouseActivityMonitorIfNeeded()

            if !isObservingNotifications {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(enterFullscreen),
                    name: .enterFullscreen,
                    object: nil
                )
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(exitFullscreen),
                    name: .exitFullscreen,
                    object: nil
                )
                isObservingNotifications = true
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidResignKey),
                name: NSWindow.didResignKeyNotification,
                object: window
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidBecomeKey),
                name: NSWindow.didBecomeKeyNotification,
                object: window
            )
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            sender.orderOut(nil)
            return false
        }

        @objc private func enterFullscreen() {
            Task { @MainActor in
                let window = observedWindow ?? NSApp.windows.first
                guard let window else { return }

                if !window.isVisible {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    window.makeKey()
                }
                NSApp.activate(ignoringOtherApps: true)

                if !window.styleMask.contains(.fullScreen) {
                    applyImmersivePresentation()
                    window.toggleFullScreen(nil)
                }
                hideCursorIfNeeded()
            }
        }

        @objc private func exitFullscreen() {
            Task { @MainActor in
                guard let window = observedWindow else { return }
                guard window.styleMask.contains(.fullScreen) else { return }
                window.toggleFullScreen(nil)
                unhideCursorIfNeeded()
                restoreNormalPresentationIfNeeded()
            }
        }

        @objc private func windowDidResignKey() {
            Task { @MainActor in
                focusManager.isWindowVisible = false
            }
        }

        @objc private func windowDidBecomeKey() {
            Task { @MainActor in
                focusManager.isWindowVisible = true
            }
        }

        private func installMouseActivityMonitorIfNeeded() {
            guard mouseActivityMonitor == nil else { return }
            mouseActivityMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
            ) { [weak self] event in
                self?.unhideCursorIfNeeded()
                return event
            }
        }

        private func hideCursorIfNeeded() {
            guard !cursorHidden else { return }
            NSCursor.hide()
            cursorHidden = true
        }

        private func unhideCursorIfNeeded() {
            guard cursorHidden else { return }
            NSCursor.unhide()
            cursorHidden = false
        }

        private func applyImmersivePresentation() {
            if savedPresentationOptions == nil {
                savedPresentationOptions = NSApp.presentationOptions
            }
            NSApp.presentationOptions = NSApp.presentationOptions.union([.autoHideMenuBar, .autoHideDock])
        }

        private func restoreNormalPresentationIfNeeded() {
            guard let savedPresentationOptions else { return }
            NSApp.presentationOptions = savedPresentationOptions
            self.savedPresentationOptions = nil
        }
    }
}
