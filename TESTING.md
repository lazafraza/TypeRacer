# TypeRacer — Manual Test Checklist

Practical smoke/regression checklist for **current uncommitted work** on branch `task/gh-8-fix-practice-mode-timer-leak-on-dismissa` (plus local diffs: WPM winner, non-host start, offline banner, Firebase auth/connectivity, nickname sync).

**Out of scope / notes**

- **Rematch** — available after merging `main` (Rematch button on results when 2+ players).
- **Settings in main app** — `SettingsView` exists but `HomeView` has no navigation to it (`showSettings` is unused). Nickname for multiplayer is edited in the **lobby** TextField.

For archive, TestFlight upload, and external beta rollout, use [TESTFLIGHT_RUNBOOK.md](TESTFLIGHT_RUNBOOK.md).

## Automated preflight (run on Mac)

```bash
cd /Users/fuzz/Desktop/Projects/TypeRacer
xcodebuild -project TypeRacer.xcodeproj -scheme TypeRacer -configuration Debug \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

Expect **BUILD SUCCEEDED**. iMessage multiplayer still requires Phase 3 on two physical devices.

### Code fixes applied during agent pass

- Auth-gated create/join with user-visible alert on failure
- Cancellable countdown task on extension dismiss
- Finished-race bubble uses `loadRace` (no spectator written to Firebase)
- No progress writes after local player finishes
- `joinRace` skips write if player node already exists
- Firebase rules: WPM cap 500, reject unknown player fields

---

## Prerequisites

| Item | Notes |
|------|--------|
| 2 physical iPhones | Same iMessage group thread |
| Xcode 15+ | Open `TypeRacer.xcodeproj`, Team `XUG77CV48T` |
| Firebase project | Realtime Database + Anonymous Auth enabled |
| Local plists | Copy `GoogleService-Info.plist` into `TypeRacer/` and `TypeRacerMessages/` (gitignored) |

---

## Phase 0: Firebase setup

- [ ] Firebase Console → **Authentication** → Sign-in method → **Anonymous** enabled
- [ ] Firebase Console → **Realtime Database** created (rules not wide open in production)
- [ ] Deploy rules from repo root:
  ```bash
  firebase deploy --only database
  ```
  Confirm `database.rules.json` requires `auth != null` for `races/*` reads/writes; player writes scoped to `auth.uid === $playerId`
- [ ] `TypeRacer/GoogleService-Info.plist` present locally (main app target)
- [ ] `TypeRacerMessages/GoogleService-Info.plist` present locally (extension target)
- [ ] App Group `group.com.typeracer.shared` on both targets (nickname / playerId)
- [ ] Clean build & run on device: no Firebase configure crash in Xcode console

---

## Phase 1: Main app — practice mode + timer/background

**Device:** single iPhone, main **TypeRacer** app (not Messages).

- [ ] Launch app → **Practice Mode** opens
- [ ] Timer stays `0:00.0` until first keystroke, then ticks every ~0.1s
- [ ] WPM updates while typing; matches rough expectation (more chars + time → higher WPM)
- [ ] Finish sentence → **Done!** + final WPM; **New Quote** resets timer/WPM/input
- [ ] **How to Play** step 5 text says highest WPM among finishers (not “first to finish”)
- [ ] Back out of Practice mid-race → re-enter: timer not still running in background
- [ ] During practice: Home → background app 10s → foreground: timer not frozen “running” incorrectly
- [ ] During practice: lock screen → unlock: same as above
- [ ] No Settings entry on home (expected until wired); nickname not required for practice

---

## Phase 2: iMessage extension smoke

**Device:** one iPhone, Messages app, TypeRacer in app drawer.

- [ ] Open group chat → Apps → TypeRacer compact card appears
- [ ] Tap **Start a Type Race!** → expands to lobby (no crash)
- [ ] Lobby shows nickname field, player list (you + crown if creator)
- [ ] **Send** inserts bubble: caption “Type Race! Tap to join”
- [ ] Collapse extension → reopen same thread: no crash, state reasonable
- [ ] Tap own race bubble → joins lobby (expanded)

---

## Phase 3: Two-device multiplayer happy path

**Devices:** iPhone A (creator), iPhone B (joiner), shared group chat.

| Step | iPhone A | iPhone B | Pass if |
|------|----------|----------|---------|
| Create | Start race → **Send** message | — | Bubble in thread |
| Join | Lobby shows 1 player | Tap bubble → lobby, 2 players | Both see both nicknames |
| Start | **Start Race** (2+ players) | Same button visible (non-host can start) | 3-2-1 countdown both devices |
| Race | Type sentence | Type sentence | Live progress bars + WPM update |
| Finish | Complete quote | Complete quote | Both reach results |
| Share | **Share Results** | — | New bubble: “{name} wins! {n} WPM” |
| Re-open | Tap finished bubble | Tap finished bubble | Results / rankings load |

- [ ] Same quote text and attribution on both devices during race
- [ ] Countdown sync: B enters racing when A starts (status `racing` in Firebase)
- [ ] DNF player still listed on results with % progress

---

## Phase 4: Auth, offline, nickname, WPM winner, non-host start

### Anonymous auth + player ID

- [ ] Fresh install (or delete app): open extension → Xcode shows no repeated auth errors
- [ ] After first race action, `localPlayerId` aligns with Firebase Auth UID (writes succeed under rules)
- [ ] Create race on A, join on B: both players appear under `races/{id}/players/` in Firebase console

### Offline banner

- [ ] Mid-race on one device: enable **Airplane Mode** ~5s
- [ ] Yellow banner: “Connection lost. Waiting to reconnect...”
- [ ] Disable airplane mode → banner clears; typing/progress resumes syncing

### Nickname sync

- [ ] In lobby on A: change nickname → B’s player list updates within ~2s
- [ ] Change nickname on B while A stays in lobby → A sees update
- [ ] Invalid empty nickname blocked by UI habit; Firebase rules reject empty/`>24` chars if forced

### WPM winner (not first finisher)

Setup: both finish the quote; **slower finisher has higher WPM** (type slower but with fewer mistakes / pause less).

- [ ] Results crown / “Winner!” shows **higher WPM** player
- [ ] **Share Results** bubble uses that winner’s name + WPM
- [ ] Tie-break: same WPM → **earlier** `finishedAt` wins

### Non-host start

- [ ] B (non-creator) sees green **Start Race** when ≥2 players (not “Waiting for host…”)
- [ ] B taps **Start Race** → countdown starts on both devices

---

## Phase 5: Regression — timer leaks & auth timing

- [ ] Practice: start timer → pop navigation back → wait 30s → no runaway CPU / ghost timer (check feel + Instruments if unsure)
- [ ] Practice: `onDisappear` + background invalidates timer (repeat Phase 1 background cases)
- [ ] Extension: start race → dismiss extension (`didResignActive`) → reopen: no duplicate timers / stuck WPM
- [ ] Extension: auth completes before create/join (rapid tap Start on cold launch — no silent no-op)
- [ ] Finished race: `progressTimer` stopped; no Firebase writes after results

---

## Pass / fail rubric

| Result | Criteria |
|--------|----------|
| **PASS** | All Phase 0 items + Phases 1–2 pass; Phase 3 happy path pass on 2 devices; Phase 4 spot-checks (auth, offline banner, nickname, WPM winner, non-host start) pass; Phase 5 regression items pass |
| **PASS with notes** | Core multiplayer works; minor UI polish only; document in notes |
| **FAIL** | Cannot auth, rules block writes, countdown/race desync, wrong winner, timer leak after background, or crash on create/join/start |

Record per run: **date**, **build** (Debug/TF), **devices**, **iOS versions**, **failures** (steps + screenshots).

---

## Debugging cheatsheet

| Symptom | Likely cause | What to check |
|---------|----------------|---------------|
| Permission denied on write | Rules not deployed or Anonymous Auth off | Console Auth + `firebase deploy --only database` |
| `GoogleService-Info.plist` missing | Plist not in target folder | Both paths under `TypeRacer/` and `TypeRacerMessages/` |
| Create/join no-op | Auth not ready | Xcode log: “Anonymous auth failed”; retry after 1–2s |
| Player not in lobby | `playerId` ≠ `auth.uid` | App group `playerId` key; `syncPlayerIdWithAuth()` |
| Start button gray | `<2` players | Second device must tap bubble to join |
| Countdown on one device only | Firebase status not updating | Network; RTDB `races/{id}/status` |
| Wrong winner | Old “first finish” logic | Confirm uncommitted `Race.winner` uses max WPM |
| Offline banner stuck | `.info/connected` false | Real network; Firebase reachability |
| Nickname not syncing | Not in lobby / no race id | Edit in lobby; `updatePlayerNickname` path |
| Timer runs in background | Timer leak | Practice `onDisappear` / `scenePhase`; GameState `cleanup()` |
| Rematch missing | Expected on this branch | Use `main` rematch branch for that test |

**Useful logs:** Xcode console filter `Anonymous auth`, `Failed to insert message`, Firebase Database debug (temporary).

**RTDB paths:** `races/{raceId}/status`, `races/{raceId}/players/{uid}/progress|wpm|finishedAt|nickname`

---

## Quick command reference

```bash
xcodegen generate
xcodebuild -project TypeRacer.xcodeproj -scheme TypeRacer -configuration Debug \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
firebase deploy --only database
```

---

*Last updated for uncommitted diff: WPM winner, any-player start, offline banner, connection monitoring, practice timer invalidation, auth UID sync.*
