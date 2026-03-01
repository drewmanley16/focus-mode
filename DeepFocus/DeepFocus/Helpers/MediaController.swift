import Foundation

enum MediaController {
    private static let scripts = [
        "if application \"Music\" is running then tell application \"Music\" to pause",
        "if application \"Spotify\" is running then tell application \"Spotify\" to pause",
        "if application \"TV\" is running then tell application \"TV\" to pause"
    ]

    static func pauseAll() {
        DispatchQueue.global(qos: .userInitiated).async {
            for script in scripts {
                let appleScript = NSAppleScript(source: script)
                appleScript?.executeAndReturnError(nil)
            }
        }
    }
}
