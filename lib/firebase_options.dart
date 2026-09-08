import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase project: tictactoe-1295a
///
/// Web uses [AppFirebaseConfig.web] explicitly. Android/iOS read
/// `google-services.json` / `GoogleService-Info.plist` automatically at build
/// time (no options needed here).
class AppFirebaseConfig {
  AppFirebaseConfig._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD4Vm_W3veM-r1TJA9feIxGu6zMOS-Adwc',
    appId: '1:430722340399:web:3a99dd0c9f4aa01f2818da',
    messagingSenderId: '430722340399',
    projectId: 'tictactoe-1295a',
    authDomain: 'tictactoe-1295a.firebaseapp.com',
    databaseURL: 'https://tictactoe-1295a-default-rtdb.firebaseio.com',
    storageBucket: 'tictactoe-1295a.firebasestorage.app',
    measurementId: 'G-66LVZWTCQK',
  );
}