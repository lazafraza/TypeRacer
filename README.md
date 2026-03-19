# TypeRacer

A multiplayer typing race game built as an iMessage app using SwiftUI and Firebase.

## Firebase Setup

This project uses Firebase Realtime Database and Anonymous Authentication.

### 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project
2. Add an iOS app with bundle ID `com.fuzzaslam.typeracer`
3. Add a second iOS app with bundle ID `com.fuzzaslam.typeracer.messages`
4. Enable **Anonymous Authentication** under Authentication > Sign-in method

### 2. Add Config Files

Download `GoogleService-Info.plist` for each target and place them at:

- `TypeRacer/GoogleService-Info.plist` (main app)
- `TypeRacerMessages/GoogleService-Info.plist` (iMessage extension)

These files are gitignored since they contain API keys.

### 3. Deploy Security Rules

Install the Firebase CLI and deploy the database security rules:

```bash
npm install -g firebase-tools
firebase login
firebase init database   # select your project
firebase deploy --only database
```

The rules are defined in `firebase-rules.json`. They ensure:

- Only authenticated users can read/write race data
- Players can only update their own player entry
- Race creation is allowed for any authenticated user
- Status and timing fields can be updated by any authenticated participant
