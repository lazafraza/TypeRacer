# TypeRacer TestFlight Runbook

Use this checklist every time you ship a TestFlight build.

## 1) App Store Connect Setup (One-time)

- [ ] Confirm Apple Developer agreements are accepted in App Store Connect.
- [ ] Confirm app record exists: `TypeRacer` with bundle ID `com.fuzzaslam.typeracer`.
- [ ] Confirm iMessage extension is embedded in the app archive (`com.fuzzaslam.typeracer.messages`).
- [ ] In Xcode Signing, both targets use Team `XUG77CV48T`.

## 2) Local Preflight

- [ ] Regenerate project from `project.yml`: `xcodegen generate`
- [ ] Re-apply iMessage extension product type patch if needed in `TypeRacer.xcodeproj/project.pbxproj`:
      `com.apple.product-type.app-extension.messages`
- [ ] Build without signing check:
      `xcodebuild -project "TypeRacer.xcodeproj" -scheme "TypeRacer" -configuration Debug -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`
- [ ] Ensure Firebase secrets are not committed (`.gitignore` includes both `GoogleService-Info.plist` files).
- [ ] Deploy `database.rules.json` to Firebase before public testing.

## 3) Archive + Upload

- [ ] In Xcode, select `Any iOS Device (arm64)`.
- [ ] Product -> Archive.
- [ ] In Organizer, Validate App.
- [ ] Distribute App -> App Store Connect -> Upload.
- [ ] Wait for TestFlight processing (usually 5-30 minutes).

## 4) Internal TestFlight Smoke Test

- [ ] Install build on 2 real iPhones.
- [ ] Verify full flow: create race -> send message -> join -> start -> finish -> share results -> rematch.
- [ ] Verify nickname change syncs to other device mid-lobby.
- [ ] Verify reconnect behavior after toggling airplane mode.
- [ ] Verify winner is highest WPM among finishers (tie by earliest finish).

## 5) External Rollout

- [ ] Add external tester group (friends).
- [ ] Complete beta app description + contact info in TestFlight.
- [ ] Submit build for Beta App Review.
- [ ] After approval, invite friends by email or public link.
- [ ] Collect first 24h bug reports and ship build `+1` if needed.
