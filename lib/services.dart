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

enum LeaderboardPeriod { weekly, monthly }

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

/// A finished match, replayable from its recorded moves.
class MatchRecord {
  final String id;
  final String mode;
  final String p1Emoji;
  final String p2Emoji;
  final String p1Name;
  final String p2Name;
  final String winner; // 'p1' | 'p2' | 'draw'
  final List<int> moves;
  final int atMs;
  const MatchRecord({
    required this.id,
    required this.mode,
    required this.p1Emoji,
    required this.p2Emoji,
    required this.p1Name,
    required this.p2Name,
    required this.winner,
    required this.moves,
    required this.atMs,
  });
}

/// An open online-PvP lobby row.
class LobbyGame {
  final String id;
  final String hostName;
  final String hostEmoji;
  final int atMs;
  const LobbyGame({
    required this.id,
    required this.hostName,
    required this.hostEmoji,
    required this.atMs,
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
  String? nickname;
  String? avatar;

  /// Human-readable reason the last auth/cloud step failed. Shown in the UI
  /// so console-side setup problems aren't silent.
  String? lastError;

  /// Per-account totals held on this device so every account that has played
  /// here appears on the leaderboard even when Firestore is unreachable.
  final Map<String, LeaderboardEntry> _localBoard = {};

  final List<MatchRecord> _recent = [];

  final GoogleSignIn _google = GoogleSignIn.instance;
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  int totalWins = 0;
  int totalDraws = 0;
  int totalGames = 0;

  bool get online => firebaseReady && user != null;

  String get displayName {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    return user?.name ?? 'You';
  }

  Future<void> init() async {
    await _initFirebase();
    await _initGoogleSignIn();
    await _loadLocalTotals();
    await _loadLocalBoard();
    await _loadProfile();
    await _loadRecent();
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

  // ── Profile (nickname + avatar sticker) ───────────────────────────────────
  void setProfile({String? name, String? avatar}) {
    if (name != null) nickname = name.trim();
    if (avatar != null) this.avatar = avatar;
    _persistProfile();
    notifyListeners();
  }

  Future<void> _persistProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ttt_nickname', nickname ?? '');
      await prefs.setString('ttt_avatar', avatar ?? '');
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('ttt_nickname');
      if (n != null && n.isNotEmpty) nickname = n;
      final a = prefs.getString('ttt_avatar');
      if (a != null && a.isNotEmpty) avatar = a;
    } catch (_) {}
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
        name: name ?? displayName,
        photoUrl: photoUrl ?? avatar ?? me.photoURL,
        wins: (prev?.wins ?? 0) + wins,
        games: (prev?.games ?? 0) + 1,
      );
      _persistLocalBoard();
    }

    if (online && _db != null && _auth != null) {
      final nm = name ?? displayName;
      final ph = photoUrl ?? avatar ?? user!.photoUrl ?? '';
      _pushToCloud(
        seasonCollection(LeaderboardPeriod.weekly),
        name: nm,
        photoUrl: ph,
        wins: wins,
        games: 1,
      );
      _pushToCloud(
        seasonCollection(LeaderboardPeriod.monthly),
        name: nm,
        photoUrl: ph,
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

  // ── Seasons ───────────────────────────────────────────────────────────────
  static String seasonCollection(LeaderboardPeriod p, [DateTime? now]) {
    final t = now ?? DateTime.now();
    return p == LeaderboardPeriod.weekly
        ? 'weekly_${t.year}-W${_weekNumber(t).toString().padLeft(2, '0')}'
        : 'monthly_${t.year}-${t.month.toString().padLeft(2, '0')}';
  }

  static int _weekNumber(DateTime date) {
    final w = DateTime.utc(date.year, date.month, date.day)
        .add(const Duration(days: 3));
    return w.difference(DateTime.utc(w.year, 1, 1)).inDays ~/ 7 + 1;
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

  void _pushToCloud(
    String collection, {
    required String name,
    required String photoUrl,
    required int wins,
    required int games,
  }) {
    try {
      final uid = _auth!.currentUser!.uid;
      _db!.collection(collection).doc(uid).set(
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
  Future<List<LeaderboardEntry>> fetchLeaderboard(
      {LeaderboardPeriod period = LeaderboardPeriod.weekly}) async {
    final Map<String, LeaderboardEntry> board = Map.of(_localBoard);

    if (online && _db != null) {
      try {
        final snap = await _db!
            .collection(seasonCollection(period))
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
        name: displayName,
        wins: totalWins,
        games: totalGames,
        photoUrl: avatar ?? user?.photoUrl,
      );
    }

    final list = board.values.toList()
      ..sort((a, b) {
        if (a.wins != b.wins) return b.wins.compareTo(a.wins);
        return b.games.compareTo(a.games);
      });
    return list.take(10).toList();
  }

  // ── Recent matches / feed / replay ────────────────────────────────────────
  void recordMatch({
    String? id,
    required String mode,
    required String p1Emoji,
    required String p2Emoji,
    required String p1Name,
    required String p2Name,
    required String winner,
    required List<int> moves,
    int? atMs,
  }) {
    final ts = atMs ?? DateTime.now().millisecondsSinceEpoch;
    final matchId =
        id ?? 'local-$ts-${DateTime.now().microsecondsSinceEpoch % 100000}';
    final record = MatchRecord(
      id: matchId,
      mode: mode,
      p1Emoji: p1Emoji,
      p2Emoji: p2Emoji,
      p1Name: p1Name,
      p2Name: p2Name,
      winner: winner,
      moves: moves,
      atMs: ts,
    );
    _recent.removeWhere((m) => m.id == matchId);
    _recent.insert(0, record);
    if (_recent.length > 20) _recent.removeRange(20, _recent.length);
    _persistRecent();

    if (online && _db != null) {
      _db!.collection('recentMatches').doc(matchId).set({
        'mode': mode,
        'p1e': p1Emoji,
        'p2e': p2Emoji,
        'p1n': p1Name,
        'p2n': p2Name,
        'winner': winner,
        'moves': moves,
        'atMs': ts,
      }).catchError((_) {});
    }
  }

  Future<void> _persistRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'ttt_recent_matches',
        jsonEncode([
          for (final m in _recent)
            {
              'id': m.id,
              'mode': m.mode,
              'p1e': m.p1Emoji,
              'p2e': m.p2Emoji,
              'p1n': m.p1Name,
              'p2n': m.p2Name,
              'winner': m.winner,
              'moves': m.moves,
              'atMs': m.atMs,
            }
        ]),
      );
    } catch (_) {}
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ttt_recent_matches');
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        _recent.add(MatchRecord(
          id: (m['id'] as String?) ?? '',
          mode: (m['mode'] as String?) ?? '',
          p1Emoji: (m['p1e'] as String?) ?? '🐶',
          p2Emoji: (m['p2e'] as String?) ?? '🐼',
          p1Name: (m['p1n'] as String?) ?? 'Player 1',
          p2Name: (m['p2n'] as String?) ?? 'Player 2',
          winner: (m['winner'] as String?) ?? 'draw',
          moves: (m['moves'] as List?)?.cast<int>() ?? const [],
          atMs: (m['atMs'] as num?)?.toInt() ?? 0,
        ));
      }
    } catch (_) {}
  }

  Future<List<MatchRecord>> fetchRecentMatches() async {
    final Map<String, MatchRecord> all = {
      for (final m in _recent) m.id: m,
    };
    if (online && _db != null) {
      try {
        final snap = await _db!
            .collection('recentMatches')
            .orderBy('atMs', descending: true)
            .limit(20)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          all[d.id] = MatchRecord(
            id: d.id,
            mode: (data['mode'] as String?) ?? '',
            p1Emoji: (data['p1e'] as String?) ?? '🐶',
            p2Emoji: (data['p2e'] as String?) ?? '🐼',
            p1Name: (data['p1n'] as String?) ?? 'Player 1',
            p2Name: (data['p2n'] as String?) ?? 'Player 2',
            winner: (data['winner'] as String?) ?? 'draw',
            moves: (data['moves'] as List?)?.cast<int>() ?? const [],
            atMs: (data['atMs'] as num?)?.toInt() ?? 0,
          );
        }
      } catch (_) {}
    }
    final list = all.values.toList()
      ..sort((a, b) => b.atMs.compareTo(a.atMs));
    return list.take(20).toList();
  }

  // ── Online PvP ────────────────────────────────────────────────────────────
  Future<List<LobbyGame>> fetchOpenGames() async {
    if (!online || _db == null) return const [];
    try {
      final q = await _db!
          .collection('onlineOpen')
          .where('status', isEqualTo: 'open')
          .get();
      final rows = q.docs
          .map((d) {
            final data = d.data();
            return LobbyGame(
              id: d.id,
              hostName: (data['hostName'] as String?) ?? 'Player',
              hostEmoji: (data['hostEmoji'] as String?) ?? '🐶',
              atMs: (data['atMs'] as num?)?.toInt() ?? 0,
            );
          })
          .toList();
      rows.sort((a, b) => b.atMs.compareTo(a.atMs));
      return rows;
    } catch (_) {
      return const [];
    }
  }

  Future<String?> createOnlineGame({
    required String hostEmoji,
    required String hostName,
  }) async {
    if (!online || _db == null || _auth == null) return null;
    try {
      final ref = _db!.collection('onlineOpen').doc();
      await ref.set({
        'hostUid': _auth!.currentUser!.uid,
        'hostName': hostName,
        'hostEmoji': hostEmoji,
        'guestName': null,
        'guestEmoji': null,
        'guestUid': null,
        'board': List<String?>.filled(9, null),
        'turn': hostEmoji,
        'moves': <int>[],
        'status': 'open',
        'atMs': DateTime.now().millisecondsSinceEpoch,
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> joinOnlineGame(
    String id, {
    required String guestEmoji,
    required String guestName,
  }) async {
    if (!online || _db == null || _auth == null) return false;
    try {
      final ref = _db!.collection('onlineOpen').doc(id);
      return await _db!.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        if (data['status'] != 'open') return false;
        tx.update(ref, {
          'guestUid': _auth!.currentUser!.uid,
          'guestName': guestName,
          'guestEmoji': guestEmoji,
          'status': 'playing',
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<void> closeOnlineGame(String id) async {
    if (_db == null) return;
    try {
      await _db!.collection('onlineOpen').doc(id).update({'status': 'closed'});
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> fetchOnlineGame(String id) async {
    if (_db == null) return null;
    try {
      final s = await _db!.collection('onlineOpen').doc(id).get();
      return s.data();
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> watchOnlineGame(String id) {
    if (_db == null) return const Stream.empty();
    return _db!
        .collection('onlineOpen')
        .doc(id)
        .snapshots()
        .map((s) => s.data());
  }

  static const List<List<int>> _winLines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  static String? _winnerOf(List<String?> board, String p1e, String p2e) {
    for (final line in _winLines) {
      final a = board[line[0]];
      if (a != null && a == board[line[1]] && a == board[line[2]]) return a;
    }
    return null;
  }

  /// Returns 0 = moved, 1 = invalid (not your turn / cell taken),
  /// 2 = game unavailable.
  Future<int> playOnlineMove(String id, int index, String emoji) async {
    if (_db == null) return 2;
    try {
      final ref = _db!.collection('onlineOpen').doc(id);
      return await _db!.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return 2;
        final d = snap.data()!;
        if (d['status'] != 'playing') return 2;
        if (d['turn'] != emoji) return 1;
        final board =
            List<String?>.from((d['board'] as List).map((e) => e as String?));
        if (board[index] != null) return 1;
        board[index] = emoji;
        final moves = List<int>.from((d['moves'] as List?)?.cast<int>() ??
            const <int>[])..add(index);
        final p1e = d['hostEmoji'] as String;
        final p2e = d['guestEmoji'] as String;
        final winner = _winnerOf(board, p1e, p2e);
        final done = winner != null || !board.contains(null);
        tx.update(ref, {
          'board': board,
          'moves': moves,
          'winner': winner ?? '',
          if (done)
            'status': 'done'
          else
            'turn': (emoji == p1e ? p2e : p1e),
        });
        return 0;
      });
    } catch (_) {
      return 2;
    }
  }
}