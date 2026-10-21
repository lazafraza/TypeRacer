# TypeRacer

A multiplayer typing race game built as an iMessage app using SwiftUI and Firebase.

## Getting started

### Prerequisites

- Xcode 15 or later (Swift 5.9, deployment target iOS 17.0)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- A Firebase project with Realtime Database and Anonymous Auth enabled
- A signing team on both targets for a device install (automatic signing, team `XUG77CV48T`)

### Generate the project

`project.yml` is the XcodeGen spec. It defines the host app **TypeRacer** and the iMessage extension **TypeRacerMessages**. Both targets compile `Shared/`. Firebase Realtime Database and Auth come from the Firebase iOS SDK (Swift Package Manager, 11.0.0+). From the repo root:

```bash
xcodegen generate
```

Open `TypeRacer.xcodeproj` and run the **TypeRacer** scheme. That scheme builds the app and the Messages extension in Debug.

Archive and TestFlight use the checked-in project. It sets the extension product type to `com.apple.product-type.app-extension.messages`. `project.yml` uses `type: app-extension`, and regenerating can drop that product type. The upload steps are in [TESTFLIGHT_RUNBOOK.md](TESTFLIGHT_RUNBOOK.md).

### Test the Messages extension

Run the extension inside **Messages** on a simulator or device: open a thread, then Apps → TypeRacer → **Start a Type Race!**. A two-player race needs two iPhones in the same iMessage thread. The manual checklist is [TESTING.md](TESTING.md).

### Firebase plists

Each target has its own file. Both paths are listed in `.gitignore`. Keep real Firebase secrets out of git.

- `TypeRacer/GoogleService-Info.plist`
- `TypeRacerMessages/GoogleService-Info.plist`

Set `DATABASE_URL` in each local file to the `https://` Realtime Database URL from the Firebase console. The copies on `main` omit that key, and the first race crashes without it. The [Security Note](#security-note) covers the copies already in the tree.

## Security Note

**Before making this repo public**, the `GoogleService-Info.plist` files (in `TypeRacer/` and `TypeRacerMessages/`) must be removed from the repo and added to `.gitignore`. These contain Firebase configuration keys that should not be exposed publicly.
