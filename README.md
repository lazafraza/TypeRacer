# TypeRacer

A multiplayer typing race game built as an iMessage app using SwiftUI and Firebase.

## Getting started

**Prerequisites:** Xcode 15 or later (deployment target iOS 17.0, Swift 5.9) and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

`project.yml` defines the host app **TypeRacer** and the iMessage extension **TypeRacerMessages**. Shared models, services, and views live in `Shared/`. Firebase Realtime Database comes from the Firebase iOS SDK (Swift Package Manager). From the repo root, generate the Xcode project:

```bash
xcodegen generate
```

Open `TypeRacer.xcodeproj` and run the **TypeRacer** scheme. That scheme builds the Messages extension as a dependency. Test the extension inside **Messages** on a simulator or device. Device installs need signing on both targets.

Each target needs its own `GoogleService-Info.plist`:

- `TypeRacer/GoogleService-Info.plist`
- `TypeRacerMessages/GoogleService-Info.plist`

Never commit real Firebase secrets. See [Security Note](#security-note).

Manual checks are in [TESTING.md](TESTING.md). Archive and TestFlight steps are in [TESTFLIGHT_RUNBOOK.md](TESTFLIGHT_RUNBOOK.md). For that upload, keep the checked-in project: its extension product type is `com.apple.product-type.app-extension.messages`. `project.yml` still uses `type: app-extension`, and regenerating can drop that product type.

## Security Note

**Before making this repo public**, the `GoogleService-Info.plist` files (in `TypeRacer/` and `TypeRacerMessages/`) must be removed from the repo and added to `.gitignore`. These contain Firebase configuration keys that should not be exposed publicly.
