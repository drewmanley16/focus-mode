# Deep Focus for macOS

Deep Focus is a native macOS focus timer app for deep work, Pomodoro cycles, and distraction-free fullscreen sessions.

Website: [site-orcin-chi.vercel.app](https://site-orcin-chi.vercel.app/)

## Why Deep Focus

- Fullscreen focus sessions with a clean, minimal timer UI
- Pomodoro mode with focus and break cycles
- Custom timers you can create and launch from the app
- Optional Deep Start countdown ritual before each session
- Menu bar controls for quick starts
- Local-first privacy: no analytics, no tracking, no account required

## Install From Terminal (Source)

```bash
git clone https://github.com/drewmanley16/focus-mode.git
cd focus-mode
open DeepFocus/DeepFocus.xcodeproj
```

Then in Xcode:

1. Select the `DeepFocus` scheme
2. Press `Run` (`Cmd + R`) to launch locally

## Build From Terminal

```bash
xcodebuild \
  -project DeepFocus/DeepFocus.xcodeproj \
  -scheme DeepFocus \
  -configuration Release \
  build
```

## Quick Usage

1. Launch Deep Focus
2. Choose `Focus`, `Pomodoro`, or `Your Timers`
3. Press Start
4. Deep Focus enters fullscreen and begins the timer

## Requirements

- macOS 14.0 or later
- Xcode 15+
- Apple Silicon or Intel Mac

## Project Structure

```text
DeepFocus/
├── DeepFocus.xcodeproj
└── DeepFocus/
    ├── DeepFocusApp.swift
    ├── AppDelegate.swift
    ├── FocusManager.swift
    ├── Views/
    ├── Audio/
    └── Helpers/

site/                 # Public landing page
archive/electron-app/ # Archived Electron prototype
```

## Privacy

Deep Focus does not collect, sell, or share personal data. Session settings and timers are stored locally on your Mac.

## Keywords

Deep focus app, focus timer, pomodoro macOS, productivity app, fullscreen timer, deep work tool.

## License

All rights reserved unless otherwise noted.

Built by Drew Manley.
