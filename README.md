# Deep Focus

A minimal focus timer for deep work. Native macOS app built with SwiftUI.

## What it does

- **Timed sessions** — 5 to 120 minute presets with a smooth progress ring
- **Do Not Disturb** — Enables macOS Focus mode during sessions
- **Pauses music** — Apple Music, Spotify, and TV
- **Ambient soundscape** — Generative audio (soft drones, filtered noise)
- **Audio-reactive visuals** — Organic blobs that pulse with the audio
- **Menu bar app** — Lives in the menu bar, no dock clutter

## Requirements

- macOS 14.0 or later
- Apple Silicon or Intel

## Building

Open `DeepFocus/DeepFocus.xcodeproj` in Xcode.

```
Product → Archive   (for TestFlight / App Store)
Product → Run       (for local testing)
```

## Project structure

```
DeepFocus/
├── DeepFocus.xcodeproj
└── DeepFocus/
    ├── DeepFocusApp.swift      # App entry
    ├── AppDelegate.swift       # Menu bar, tray
    ├── FocusManager.swift      # Session state
    ├── Views/                  # SwiftUI views
    ├── Audio/                  # AmbientAudioEngine
    ├── Helpers/                # DND, Media control
    └── Assets.xcassets

archive/electron-app/           # Archived Electron version
site/                           # Marketing / landing page
```

## Distribution

- **TestFlight** — Archive in Xcode, upload via Organizer
- **App Store** — Same archive, submit for review

---

Built by Drew Manley
