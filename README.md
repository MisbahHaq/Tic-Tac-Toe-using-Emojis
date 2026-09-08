# Flutter Emoji Tic Tac Toe

A fun and modern **Tic Tac Toe** game built with **Flutter**, using emojis instead of the traditional X and O.
Neo-Brutalist UI, a 💎 diamond currency, unlockable fighters, game modes (2P / VS AI), Google Sign-In and an online leaderboard.

https://github.com/user-attachments/assets/3e689115-ff6e-41d8-bc0a-d4cc4d367c86

## 🚀 Features
- 🎨 Emoji-based Tic Tac Toe gameplay
- 👥 2 Player mode + 🤖 VS AI (Easy = random, Hard = minimax)
- 💎 Win matches to earn diamonds; spend them to unlock new fighters in the store
- 📱 Responsive layout (phones, tablets, web)
- 🔐 Google Sign-In + 🌐 cloud leaderboard (falls back to local totals when Firebase isn't set up or you're offline)
- 🖌 Neo-Brutalist design: hard shadows, thick borders, tactile presses

---

## 🎯 How to Play
1. Pick a mode: **2 PLAYER**, **VS AI · EASY**, or **VS AI · HARD**.
2. Pick your fighter (and Player 2's) on the emoji selection screen.
3. First to align 3 emojis in a row, column, or diagonal wins — and earns 💎 diamonds!
4. Spend diamonds in the **EMOJI STORE** to unlock more fighters.

---

## 🔑 Firebase + Google Sign-In (leaderboard)

The app is designed to run **without** Firebase: it saves scores locally and
shows a graceful "not set up" notice. To enable the online leaderboard, do this
once (takes ~3 minutes):

### 1. Create a Firebase project
1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **Add project**.
2. Add your app:
   - **Android**: package name must match the one in `android/app/build.gradle.kts`
     (default: `com.example.game`; check `applicationId`).
   - **Web** (optional): "Add web app" and copy its `firebaseConfig` snippet.

### 2. Enable Google Sign-In
1. In Firebase Console → **Authentication** → **Sign-in method** → enable **Google**.
2. Android only — register the **debug SHA-1** of your signing key so real devices can sign in:
   ```
   keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
   ```
   Copy the **SHA-1** value into Firebase Console → your Android app → **Add fingerprint**.
   (For release builds, do the same with your release keystore.)

### 3. Enable Firestore
1. Firebase Console → **Firestore Database** → **Create database** → Start in **test mode** (locked-down rules later) → pick a region.
2. After going live, tighten rules to only allow signed-in writes, e.g.:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /leaderboard/{userId} {
         allow read: if true;
         allow write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### 4. Add config files
- **Android**: download `google-services.json` from Firebase Console and drop it in
  `android/app/`. The Gradle plugin is already wired to apply only when that file exists,
  so the build works with or without it.
- **Web**: paste the `firebaseConfig` into `flutter_web/firebase-config.js` (create it if
  missing) and load it before the app starts — or hardcode it in `web/index.html`.

### 5. Run
```
flutter run
```
When Firebase is configured you'll see **SIGN IN FOR LEADERBOARD** on the home
screen. Without it you can still play in local mode.

---

## 🧪 Tests
```
flutter analyze
flutter test
```

## 🏗 Build
```
flutter run          # run on a device/emulator
flutter build apk    # Android release
flutter build web    # web
```

Note: `flutter build web` here currently fails on a toolchain issue
(`Error: not found: 'dart:ui_web'`) in this environment's web SDK; Android builds are fine.