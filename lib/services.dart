import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kWins = 'wins';
const String kGames = 'games';
const String kDraws = 'draws';
const String kName = 'name';
const String kPhoto = 'photoUrl';

class AppUserProfile {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  const AppUserProfile({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
  });
}

class LeaderboardEntry {
  final String name;
  final int wins;
  final int games;
  final String? photoUrl;
  const LeaderboardEntry({
    required this.name,
    required this.wins,
    required this.games,
    this.photoUrl,
  });
}

/// Wraps Firebase Auth + Firestore + local fallback storage.
///
/// Designed to degrade gracefully: if Firebase isn't configured yet
/// (no google-services.json / no web firebase config) the app stays fully
/// usable in "local mode" — sign-in buttons just explain what's needed.
class AppServices extends ChangeNotifier {
  bool firebaseReady = false;
  bool googleInitialized = false;
  AppUserProfile? user;

  final GoogleSignIn _google = GoogleSignIn.instance;
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  int totalWins = 0;
  int totalDraws = 0;
  int totalGames = 0;

  bool get online => firebaseReady && user != null;

  Future<void> init() async {
    await _initFirebase();
    await _initGoogleSignIn();
    await _loadLocalTotals();
    notifyListeners();
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      firebaseReady = true;
      final u = _auth!.currentUser;
      if (u != null) {
        user = AppUserProfile(
          uid: u.uid,
          name: u.displayName ?? 'Player',
          email: u.email,
          photoUrl: u.photoURL,
        );
      }
    } catch (_) {
      firebaseReady = false;
      _auth = null;
      _db = null;
    }
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await _google.initialize();
      googleInitialized = true;
    } catch (_) {
      googleInitialized = false;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      if (!firebaseReady) await _initFirebase();
      if (!firebaseReady) return false;
      if (!googleInitialized) await _initGoogleSignIn();
      if (!googleInitialized) return false;

      final account = await _google.authenticate();

      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      final result = await _auth!.signInWithCredential(credential);
      final u = result.user;
      if (u == null) return false;

      user = AppUserProfile(
        uid: u.uid,
        name: u.displayName ?? u.email ?? 'Player',
        email: u.email,
        photoUrl: u.photoURL,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
      await _auth?.signOut();
    } catch (_) {}
    user = null;
    notifyListeners();
  }

  // ── Scores / leaderboard ─────────────────────────────────────────────────
  void recordResult({
    required bool p1Win,
    required bool p2Win,
    String? name,
    String? photoUrl,
  }) {
    final isDraw = !p1Win && !p2Win;
    totalGames += 1;
    if (p1Win) totalWins += 1;
    if (p2Win) totalWins += 1;
    if (isDraw) totalDraws += 1;
    _persistLocalTotals();

    if (online && _db != null && _auth != null) {
      _pushToCloud(
        name: name ?? user!.name,
        photoUrl: photoUrl ?? user!.photoUrl ?? '',
        wins: (p1Win || p2Win) ? 1 : 0,
        games: 1,
      );
    }
    notifyListeners();
  }

  Future<void> _persistLocalTotals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kWins, totalWins);
      await prefs.setInt(kDraws, totalDraws);
      await prefs.setInt(kGames, totalGames);
    } catch (_) {}
  }

  Future<void> _loadLocalTotals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      totalWins = prefs.getInt(kWins) ?? 0;
      totalDraws = prefs.getInt(kDraws) ?? 0;
      totalGames = prefs.getInt(kGames) ?? 0;
    } catch (_) {}
  }

  void _pushToCloud({
    required String name,
    required String photoUrl,
    required int wins,
    required int games,
  }) {
    try {
      final uid = _auth!.currentUser!.uid;
      _db!.collection('leaderboard').doc(uid).set(
        {
          kName: name,
          kPhoto: photoUrl,
          kWins: FieldValue.increment(wins),
          kGames: FieldValue.increment(games),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// Top leaderboard rows: cloud when available & signed in, otherwise the
  /// device's own totals.
  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    if (online && _db != null) {
      try {
        final snap = await _db!
            .collection('leaderboard')
            .orderBy(kWins, descending: true)
            .limit(10)
            .get();
        return snap.docs
            .map(
              (d) => LeaderboardEntry(
                name: (d.data()[kName] as String?) ?? 'Player',
                wins: (d.data()[kWins] as num?)?.toInt() ?? 0,
                games: (d.data()[kGames] as num?)?.toInt() ?? 0,
                photoUrl: (d.data()[kPhoto] as String?) ?? '',
              ),
            )
            .toList();
      } catch (_) {}
    }
    return [
      LeaderboardEntry(
        name: user?.name ?? 'You (this device)',
        wins: totalWins,
        games: totalGames,
        photoUrl: user?.photoUrl,
      ),
    ];
  }
}