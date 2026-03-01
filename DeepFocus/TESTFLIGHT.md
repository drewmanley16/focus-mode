# TestFlight / App Store Upload

## Prerequisites

1. **App Store Connect** — Create an app record at [appstoreconnect.apple.com](https://appstoreconnect.apple.com) with bundle ID `com.deepfocusapp.app`
2. **Apple Distribution certificate** — In Xcode: Xcode → Settings → Accounts → [Your Apple ID] → Manage Certificates → "+" → Apple Distribution
3. **Provisioning profile** — Xcode will create this automatically when you Archive (with "Automatically manage signing")

## Steps to upload to TestFlight

### Option A: Xcode (recommended)

1. Open `DeepFocus.xcodeproj` in Xcode
2. Select the **Deep Focus** scheme and **Any Mac (arm64)** destination
3. **Product → Archive**
4. When the Organizer opens, select your archive and click **Distribute App**
5. Choose **App Store Connect** → **Upload**
6. Follow the prompts (automatically manage signing, upload)
7. In App Store Connect, the build will appear under TestFlight within 10–30 minutes

### Option B: Command line

```bash
# From project root
cd DeepFocus

# Create archive
xcodebuild -project DeepFocus.xcodeproj -scheme "Deep Focus" \
  -configuration Release -destination "generic/platform=macOS" \
  -archivePath build/DeepFocus.xcarchive archive

# Export for App Store Connect (requires ExportOptions.plist)
xcodebuild -exportArchive -archivePath build/DeepFocus.xcarchive \
  -exportPath build/Export -exportOptionsPlist ExportOptions.plist

# Upload (uses Apple ID; you may be prompted for password/app-specific password)
# Output will be build/Export/*.pkg
xcrun altool --upload-app -f build/Export/*.pkg -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD
```

## First-time setup

- Ensure **Signing & Capabilities** has your Team (X9H68STU8F) selected
- For **Release** builds, Xcode uses the Apple Distribution identity when archiving
- If you see signing errors, check that your Apple Developer account has App Store distribution enabled

## Notes

- **DND / Media control** — Uses shell and Apple Events. Both work for direct installs. For Mac App Store, DND via `defaults`/`killall` may be restricted; TestFlight allows it for testing.
- **NSAppleEventsUsageDescription** — Already in Info.plist for Music/Spotify/TV control
