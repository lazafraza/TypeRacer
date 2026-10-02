# TypeRacer — External TestFlight + Public Link

Human steps for Fazal on Fazals-MacBook-Pro. Checkout: `/Users/fuzz/Desktop/Projects/TypeRacer`.

Locked path: **External TestFlight, then a Public Link.** Girlfriend installs from that link. She does not join the Apple Developer team and does not create an account in the app.

Two-player play is the existing iMessage race (create → Send → tap bubble → Start → type → finish → rematch). Do not add another multiplayer mode.

## 0) Before Archive

- [ ] Pull `main` (includes the rules fix that allows player `id` and `isCreator`).
- [ ] Confirm Aloe’s unsigned build succeeded:
      `xcodebuild -project TypeRacer.xcodeproj -scheme TypeRacer -configuration Debug -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`
- [ ] Do **not** run `xcodegen generate`. The checked-in project already sets the extension product type to `com.apple.product-type.app-extension.messages`. Regenerating from `project.yml` can drop that.
- [ ] On both plists, confirm `DATABASE_URL` is a non-empty `https://` URL:

      ```bash
      plutil -extract DATABASE_URL raw TypeRacer/GoogleService-Info.plist
      plutil -extract DATABASE_URL raw TypeRacerMessages/GoogleService-Info.plist
      ```

      The copies committed on `main` have no `DATABASE_URL` key. `Database.database()` then crashes on first race. If either command fails, Firebase Console → project `typeracer-9bad0` → Realtime Database → copy the URL at the top of the Data tab into **both** plists as key `DATABASE_URL`. Do not invent the URL.
- [ ] Firebase Console → Authentication → Sign-in method → **Anonymous** enabled.
- [ ] Deploy rules (from the repo root, after `firebase login`):

      ```bash
      firebase deploy --only database
      ```

      `firebase.json` targets `database.rules.json`. `.firebaserc` default project is `typeracer-9bad0`.
- [ ] If App Store Connect already has build `1.0 (1)`, bump `CFBundleVersion` in **both** `TypeRacer/Info.plist` and `TypeRacerMessages/Info.plist` to the same new integer. Those plists hardcode `1.0` / `1`. Changing only `project.yml` does not change the archive.

## 1) Signing

Team `XUG77CV48T`. Bundle IDs: `com.fuzzaslam.typeracer` and `com.fuzzaslam.typeracer.messages`. App Group on both: `group.com.typeracer.shared`.

- [ ] Xcode 26.6 → Settings → Accounts → `rockzegex@gmail.com` → team Fazal Aslam (`XUG77CV48T`) → **Download Manual Profiles**.
      `~/Library/MobileDevice/Provisioning Profiles` was empty. Archive uses **Apple Distribution: Fazal Aslam (XUG77CV48T)**. Automatic signing should create the App Store profiles. If it cannot, register the two bundle IDs and the app group in the developer portal, then download profiles again.
- [ ] Both targets: Signing & Capabilities → Automatically manage signing → Team `XUG77CV48T`.

## 2) Archive → Validate → Upload

- [ ] Open `TypeRacer.xcodeproj`. Scheme **TypeRacer**. Destination **Any iOS Device (arm64)**.
- [ ] Product → Archive (Release).
- [ ] Organizer → **Validate App**.
- [ ] Export compliance: **No** non-exempt encryption (HTTPS only). The plists do not set `ITSAppUsesNonExemptEncryption`, so the wizard asks.
- [ ] **Distribute App** → App Store Connect → Upload.
- [ ] Wait until the build is processed in App Store Connect (not stuck on Missing Compliance).

## 3) External testers → Public Link

Apple requires an internal group to exist before an external group. Girlfriend still uses only the public link.

- [ ] App Store Connect → Apps → TypeRacer (`com.fuzzaslam.typeracer`) → TestFlight.
- [ ] Test Information: paste the beta description and “What to Test” from `TESTFLIGHT_BETA_METADATA.md`. Feedback email must be a real inbox (the file’s `fazal@example.com` is a placeholder).
- [ ] Create an **internal** group if none exists. Fazal can be the only member. Do not add her Apple ID to Users and Access.
- [ ] Create an **external** group. Add this build. Submit for **Beta App Review**.
- [ ] Review notes to paste:

      > iMessage extension. No login. Install on two iPhones (iOS 17+), open TypeRacer once, then in Messages (blue iMessage thread) open the TypeRacer app, tap “Start a Type Race!” twice, tap Send. The other phone taps the bubble, then either person taps Start Race. Highest WPM among finishers wins.

- [ ] After the build is **Approved**, open the external group → Public Link → Enable. Optionally limit the link (iPhone, iOS 17+).
- [ ] Send her only that public link.

## 4) What she does

- [ ] iPhone on iOS 17 or later, signed into iMessage (the thread with Fazal must be blue, not green SMS).
- [ ] Install Apple’s TestFlight app, open the public link, accept, install TypeRacer.
- [ ] Open TypeRacer once from the home screen (registers the iMessage app). Practice Mode on that screen is solo. Ignore it.
- [ ] When Fazal’s bubble arrives (“Type Race! Tap to join”), tap it. Nickname is edited in the lobby. No account.

## 5) What Fazal does in Messages

- [ ] Same install. Messages → her thread → Apps → TypeRacer.
- [ ] Tap **Start a Type Race!** once to expand, again to create the race and insert the bubble, then tap **Send**.
- [ ] When her name is in the lobby (2 players), either phone taps **Start Race**.
- [ ] Both type the same quote. Results appear after **both** finish. Rematch is on that results screen.
