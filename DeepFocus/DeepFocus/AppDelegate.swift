import AppKit
import SwiftUI

extension Notification.Name {
    static let startFocus = Notification.Name("startFocus")
    static let stopFocus = Notification.Name("stopFocus")
    static let focusStateChanged = Notification.Name("focusStateChanged")
    static let enterFullscreen = Notification.Name("enterFullscreen")
    static let exitFullscreen = Notification.Name("exitFullscreen")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    let focusManager = FocusManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        createStatusItem()
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu), name: .focusStateChanged, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: .stopFocus, object: nil)
        focusManager.prepareForQuit()
        NSCursor.unhide()
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = createTrayIcon(active: false)
        statusItem?.button?.image?.isTemplate = true
        statusItem?.button?.toolTip = "Deep Focus"

        statusItem?.button?.action = #selector(trayClicked)
        statusItem?.button?.target = self

        buildMenu()
    }

    @objc private func trayClicked() {
        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("ContentView") == true }) ?? NSApp.windows.first else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func rebuildMenu() {
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        if focusManager.isFocusing {
            menu.addItem(NSMenuItem(title: focusManager.statusTitle, action: nil, keyEquivalent: ""))
            let endItem = NSMenuItem(title: "End Session", action: #selector(endSession), keyEquivalent: "")
            endItem.target = self
            menu.addItem(endItem)
        } else {
            let openItem = NSMenuItem(title: "Open Deep Focus", action: #selector(openWindow), keyEquivalent: "")
            openItem.target = self
            menu.addItem(openItem)

            let lockInMenu = NSMenu()
            for minutes in FocusManager.durationOptions {
                let label = minutes >= 60 ? "\(minutes / 60) hour\(minutes > 60 ? "s" : "")" : "\(minutes) minutes"
                let item = NSMenuItem(title: label, action: #selector(lockInSelected(_:)), keyEquivalent: "")
                item.target = self
                item.tag = minutes
                lockInMenu.addItem(item)
            }
            lockInMenu.addItem(NSMenuItem.separator())
            let customItem = NSMenuItem(title: "Custom duration…", action: #selector(showCustomDuration), keyEquivalent: "")
            customItem.target = self
            lockInMenu.addItem(customItem)
            let lockInItem = NSMenuItem(title: "Start focus", action: nil, keyEquivalent: "")
            lockInItem.submenu = lockInMenu
            menu.addItem(lockInItem)

            let pomodoroMenu = NSMenu()
            for preset in FocusManager.pomodoroPresets {
                let item = NSMenuItem(
                    title: "\(preset.name)  (\(preset.focusMinutes)m focus / \(preset.breakMinutes)m break)",
                    action: #selector(startPomodoroSelected(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = preset.name
                pomodoroMenu.addItem(item)
            }
            let pomodoroItem = NSMenuItem(title: "Pomodoro", action: nil, keyEquivalent: "")
            pomodoroItem.submenu = pomodoroMenu
            pomodoroItem.isEnabled = focusManager.pomodoroEnabled
            menu.addItem(pomodoroItem)

            let yourTimersMenu = NSMenu()
            if focusManager.customTimers.isEmpty {
                yourTimersMenu.addItem(NSMenuItem(title: "No custom timers yet", action: nil, keyEquivalent: ""))
            } else {
                for timer in focusManager.customTimers {
                    let title: String
                    if let breakMinutes = timer.breakMinutes, breakMinutes > 0 {
                        title = "\(timer.name)  (\(timer.focusMinutes)m/\(breakMinutes)m)"
                    } else {
                        title = "\(timer.name)  (\(timer.focusMinutes)m)"
                    }
                    let item = NSMenuItem(title: title, action: #selector(startCustomTimerSelected(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = timer.id.uuidString
                    yourTimersMenu.addItem(item)
                }
            }
            let yourTimersItem = NSMenuItem(title: "Your Timers", action: nil, keyEquivalent: "")
            yourTimersItem.submenu = yourTimersMenu
            menu.addItem(yourTimersItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func endSession() {
        focusManager.exitFocus()
    }

    @objc private func openWindow() {
        guard let window = NSApp.windows.first else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func lockInSelected(_ sender: NSMenuItem) {
        let minutes = sender.tag
        openWindow()
        DispatchQueue.main.async {
            self.focusManager.enterStandardFocus(minutes: minutes)
        }
    }

    @objc private func startPomodoroSelected(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let preset = FocusManager.pomodoroPresets.first(where: { $0.name == name }) else { return }
        openWindow()
        DispatchQueue.main.async {
            self.focusManager.enterPomodoro(preset)
        }
    }

    @objc private func startCustomTimerSelected(_ sender: NSMenuItem) {
        guard let idString = sender.representedObject as? String,
              let id = UUID(uuidString: idString),
              let timer = focusManager.customTimers.first(where: { $0.id == id }) else { return }
        openWindow()
        DispatchQueue.main.async {
            self.focusManager.startCustomTimer(timer)
        }
    }

    @objc private func showCustomDuration() {
        let alert = NSAlert()
        alert.messageText = "Custom duration"
        alert.informativeText = "Enter minutes (1–240):"
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "\(focusManager.durationMinutes)"
        textField.placeholderString = "e.g. 25"
        alert.accessoryView = textField
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        alert.window.makeFirstResponder(textField)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let minutes = Int(trimmed), minutes >= 1, minutes <= 240 {
                openWindow()
                DispatchQueue.main.async {
                    self.focusManager.enterStandardFocus(minutes: minutes)
                }
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func createTrayIcon(active: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(x: 2, y: 2, width: 18, height: 18)
        let path = NSBezierPath(ovalIn: rect)
        if active {
            NSColor.white.setFill()
            path.fill()
            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: 8.5, y: 8.5, width: 5, height: 5)).fill()
        } else {
            path.lineWidth = 1.5
            NSColor.labelColor.setStroke()
            path.stroke()
            NSColor.labelColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: 8.5, y: 8.5, width: 5, height: 5)).fill()
        }

        image.unlockFocus()
        return image
    }
}
