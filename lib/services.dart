import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

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
  final String uid;
  final String name;
  final int wins;
  final int games;
  final String? photoUrl;
  const LeaderboardEntry({
    this.uid = '',
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

  /// Human-readable reason the last auth/cloud step failed. Shown in the UI
  /// so console-side setup problems aren't silent.
  String? lastError;

  /// Per-account totals held on this device so every account that has played
  /// here appears on the leaderboard even when Firestore is unreachable.
  final Map<String, LeaderboardEntry> _localBoard = {};

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
    await _loadLocalBoard();
    notifyListeners();
  }

  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          await Firebase.initializeApp(options: AppFirebaseConfig.web);
        } else {
          await Firebase.initializeApp();
        }
      }
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      firebaseReady = true;
      lastError = null;
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
      lastError = 'FIREBASE INIT FAILED — MISSING google-services.json (ANDROID) '
          'OR BROKEN WEB CONFIG. PLAYING LOCALLY FOR NOW.';
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
    // Don't lazy-init here: awaiting inside the tap handler breaks the
    // browser's user-gesture chain, so the popup gets blocked. init() already
    // runs at app start; if it isn't ready yet, surface the reason instead.
    if (!firebaseReady) {
      lastError = 'FIREBASE ISN\'T READY YET — CAN\'T SIGN IN. '
          'CHECK google-services.json (ANDROID) OR THE WEB CONFIG.';
      return false;
    }
    try {
      if (kIsWeb) {
        // Web: Firebase popup flow directly (no google_sign_in plugin).
        final provider = GoogleAuthProvider();
        final result = await _auth!.signInWithPopup(provider);
        if (result.user == null) {
          lastError = 'SIGN-IN CANCELLED.';
          return false;
        }
        lastError = null;
        return _adopt(result.user!);
      }

      if (!googleInitialized) await _initGoogleSignIn();
      if (!googleInitialized) {
        lastError = 'GOOGLE SIGN-IN ISN\'T AVAILABLE ON THIS DEVICE.';
        return false;
      }

      final account = await _google.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      final result = await _auth!.signInWithCredential(credential);
      final u = result.user;
      if (u == null) {
        lastError = 'SIGN-IN CANCELLED.';
        return false;
      }
      lastError = null;
      return _adopt(u);
    } on FirebaseAuthException catch (e) {
      lastError = switch (e.code) {
        'popup-blocked' => 'POPUP BLOCKED — ALLOW POP-UPS FOR THIS SITE.',
        'popup-closed-by-user' || 'cancelled-popup-request' =>
          'SIGN-IN CANCELLED.',
        'operation-not-allowed' => 'GOOGLE SIGN-IN IS DISABLED IN THE '
            'FIREBASE CONSOLE (AUTHENTICATION → SIGN-IN METHOD).',
        'unauthorized-domain' => 'THIS DOMAIN ISN\'T ALLOWED — ADD IT UNDER '
            'FIREBASE CONSOLE → AUTHENTICATION → SETTINGS → '
            'AUTHORIZED DOMAINS.',
        _ => 'SIGN-IN FAILED (${e.code}). CHECK FIREBASE CONSOLE SETUP.',
      };
      return false;
    } catch (_) {
      lastError = 'SIGN-IN FAILED — CHECK FIREBASE CONSOLE SETUP.';
      return false;
    }
  }

  bool _adopt(User u) {
    user = AppUserProfile(
      uid: u.uid,
      name: u.displayName ?? u.email ?? 'Player',
      email: u.email,
      photoUrl: u.photoURL,
    );
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await _google.signOut();
      await _auth?.signOut();
    } catch (_) {}
    user = null;
    lastError = null;
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

    final wins = (p1Win || p2Win) ? 1 : 0;
    final me = _auth?.currentUser;

    // Always bump the per-account row so every signed-in account that plays
    // on this device shows up, even if cloud sync is unavailable right now.
    if (me != null) {
      final uid = me.uid;
      final prev = _localBoard[uid];
      _localBoard[uid] = LeaderboardEntry(
        uid: uid,
        name: name ?? user?.name ?? me.displayName ?? 'Player',
        photoUrl: photoUrl ?? user?.photoUrl ?? me.photoURL,
        wins: (prev?.wins ?? 0) + wins,
        games: (prev?.games ?? 0) + 1,
      );
      _persistLocalBoard();
    }

    if (online && _db != null && _auth != null) {
      _pushToCloud(
        name: name ?? user!.name,
        photoUrl: photoUrl ?? user!.photoUrl ?? '',
        wins: wins,
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

  static const String _localBoardKey = 'local_leaderboard';

  void _persistLocalBoard() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) => p.setString(
            _localBoardKey,
            jsonEncode({
              for (final e in _localBoard.entries)
                e.key: {
                  'n': e.value.name,
                  'p': e.value.photoUrl ?? '',
                  'w': e.value.wins,
                  'g': e.value.games,
                }
            }),
          ));
    } catch (_) {}
  }

  Future<void> _loadLocalBoard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localBoardKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        final v = e.value as Map<String, dynamic>;
        _localBoard[e.key] = LeaderboardEntry(
          uid: e.key,
          name: (v['n'] as String?) ?? 'Player',
          photoUrl: (v['p'] as String?) ?? '',
          wins: (v['w'] as num?)?.toInt() ?? 0,
          games: (v['g'] as num?)?.toInt() ?? 0,
        );
      }
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
      ).then((_) {
        if (lastError != null) {
          lastError = null;
          notifyListeners();
        }
      }).catchError((_) {
        lastError = 'CLOUD SAVE FAILED — IS FIRESTORE CREATED? '
            'CHECK FIRESTORE DATABASE → CREATE DATABASE.';
        notifyListeners();
      });
    } catch (_) {}
  }

  /// Leaderboard rows: cloud rows (when online) merged with every account
  /// that has played on this device, so a signed-in account is always
  /// visible even if the cloud can't be reached.
  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final Map<String, LeaderboardEntry> board = Map.of(_localBoard);

    if (online && _db != null) {
      try {
        final snap = await _db!
            .collection('leaderboard')
            .orderBy(kWins, descending: true)
            .limit(10)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          board[d.id] = LeaderboardEntry(
            uid: d.id,
            name: (data[kName] as String?) ?? 'Player',
            wins: (data[kWins] as num?)?.toInt() ?? 0,
            games: (data[kGames] as num?)?.toInt() ?? 0,
            photoUrl: (data[kPhoto] as String?) ?? '',
          );
        }
        lastError = null;
      } catch (_) {
        lastError = 'ONLINE LEADERBOARD UNAVAILABLE — SOME ROWS ARE '
            'FROM THIS DEVICE ONLY. IS FIRESTORE CREATED?';
      }
    }

    if (board.isEmpty) {
      board['__device__'] = LeaderboardEntry(
        name: user?.name ?? 'You (this device)',
        wins: totalWins,
        games: totalGames,
        photoUrl: user?.photoUrl,
      );
    }

    final list = board.values.toList()
      ..sort((a, b) {
        if (a.wins != b.wins) return b.wins.compareTo(a.wins);
        return b.games.compareTo(a.games);
      });
    return list.take(10).toList();
  }
}