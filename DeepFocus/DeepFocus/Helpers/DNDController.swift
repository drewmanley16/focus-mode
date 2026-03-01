import Foundation
import AppKit

enum DNDController {
    static func enable() {
        // Temporarily disabled while isolating session-start hangs.
        return
    }

    static func disable() {
        // Temporarily disabled while isolating session-start hangs.
        return
    }

    private static func runShellAsync(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
            do {
                try process.run()
            } catch {
                return
            }
            process.waitUntilExit()
        }
    }
}
