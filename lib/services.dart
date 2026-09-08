import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kWins = 'wins';
const String _kGames = 'games';
const String _kDraws = 'draws';
const String _kName = 'name';
const String _kPhoto = 'photoUrl';

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
  AppUserProfile? user;

  final GoogleSignIn _google = GoogleSignIn.standard();
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  int totalWins = 0;
  int totalDraws = 0;
  int totalGames = 0;

  bool get online => firebaseReady && user != null;

  Future<void> init() async {
    await _initFirebase();
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

  // ── Auth ─────────────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      if (!firebaseReady) await _initFirebase();
      if (!firebaseReady) return false;

      final account = await _google.signInSilently();
      if (account == null) return false; // user cancelled

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
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
      await prefs.setInt(_kWins, totalWins);
      await prefs.setInt(_kDraws, totalDraws);
      await prefs.setInt(_kGames, totalGames);
    } catch (_) {}
  }

  Future<void> _loadLocalTotals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      totalWins = prefs.getInt(_kWins) ?? 0;
      totalDraws = prefs.getInt(_kDraws) ?? 0;
      totalGames = prefs.getInt(_kGames) ?? 0;
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
          _kName: name,
          _kPhoto: photoUrl,
          _kWins: FieldValue.increment(wins),
          _kGames: FieldValue.increment(games),
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
            .orderBy(_kWins, descending: true)
            .limit(10)
            .get();
        return snap.docs
            .map(
              (d) => LeaderboardEntry(
                name: (d.data()[_kName] as String?) ?? 'Player',
                wins: (d.data()[_kWins] as num?)?.toInt() ?? 0,
                games: (d.data()[_kGames] as num?)?.toInt() ?? 0,
                photoUrl: (d.data()[_kPhoto] as String?) ?? '',
              ),
            )
            .toList();
      } catch (_) {}
    }
    // Local fallback: this device's totals.
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