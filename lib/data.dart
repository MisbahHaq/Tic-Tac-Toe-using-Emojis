import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';

enum GameMode { twoPlayer, vsAiEasy, vsAiHard }

extension GameModeLabel on GameMode {
  String get label => switch (this) {
        GameMode.twoPlayer => '2 PLAYER',
        GameMode.vsAiEasy => 'VS AI · EASY',
        GameMode.vsAiHard => 'VS AI · HARD',
      };

  bool get isAi => this != GameMode.twoPlayer;
}

class EmojiItem {
  final String emoji;
  final String name;
  final int price; // 0 = free / unlocked by default
  const EmojiItem(this.emoji, this.name, this.price);
}

const List<EmojiItem> kCatalog = [
  // Free (unlocked by default)
  EmojiItem('🐶', 'Dog', 0),
  EmojiItem('😸', 'Cat', 0),
  EmojiItem('🐼', 'Panda', 0),
  EmojiItem('🐵', 'Monkey', 0),
  EmojiItem('🦊', 'Fox', 0),
  EmojiItem('🐻', 'Bear', 0),
  EmojiItem('🐨', 'Koala', 0),
  EmojiItem('🐯', 'Tiger', 0),
  EmojiItem('🐸', 'Frog', 0),
  EmojiItem('🦁', 'Lion', 0),
  EmojiItem('🐮', 'Cow', 0),
  EmojiItem('🦄', 'Unicorn', 0),
  // Premium (purchasable with diamonds)
  EmojiItem('🐙', 'Octopus', 6),
  EmojiItem('🐢', 'Turtle', 6),
  EmojiItem('🖐', 'Hand', 6),
  EmojiItem('🤝', 'Handshake', 6),
  EmojiItem('👏', 'Clap', 6),
  EmojiItem('🙌', 'Cheers', 6),
  EmojiItem('🍭', 'Lollipop', 6),
  EmojiItem('🐝', 'Bee', 8),
  EmojiItem('🦋', 'Butterfly', 8),
  EmojiItem('🦴', 'Bone', 8),
  EmojiItem('🦍', 'Gorilla', 12),
  EmojiItem('🐳', 'Whale', 12),
  EmojiItem('🐍', 'Snake', 12),
  EmojiItem('🤡', 'Clown', 15),
  EmojiItem('👽', 'Alien', 15),
];

const int kWinReward = 5; // diamonds earned per win (before streak multiplier)
const int kStartingDiamonds = 6;
const int kDailyBonus = 10;
const int kQuestWinReward = 20;
const int kQuestPlayReward = 15;
const int kQuestStreakReward = 10;
const String kAiEmoji = '🤖';

// ────────────────────────────────────────────────────────────────────────────
//  Board themes & frames (unlockable with diamonds)
// ────────────────────────────────────────────────────────────────────────────
class BoardTheme {
  final String id;
  final String name;
  final String preview; // emoji shown in the store
  final Color boardBg; // behind the cells
  final Color cellBg; // empty cell
  final Color accent; // win / highlight
  final int price; // 0 = free
  const BoardTheme({
    required this.id,
    required this.name,
    required this.preview,
    required this.boardBg,
    required this.cellBg,
    required this.accent,
    this.price = 0,
  });
}

const List<BoardTheme> kBoardThemes = [
  BoardTheme(
    id: 'classic',
    name: 'Classic',
    preview: '⬜',
    boardBg: Color(0xFFFAF7F2),
    cellBg: Colors.white,
    accent: Color(0xFFFDE047),
  ),
  BoardTheme(
    id: 'mint',
    name: 'Mint',
    preview: '🍃',
    boardBg: Color(0xFFD9F99D),
    cellBg: Color(0xFFF7FEE7),
    accent: Color(0xFF65A30D),
  ),
  BoardTheme(
    id: 'ocean',
    name: 'Ocean',
    preview: '🌊',
    boardBg: Color(0xFF7DD3FC),
    cellBg: Color(0xFFECFEFF),
    accent: Color(0xFF0369A1),
  ),
  BoardTheme(
    id: 'sunset',
    name: 'Sunset',
    preview: '🌇',
    boardBg: Color(0xFFFDA4AF),
    cellBg: Color(0xFFFFF1F2),
    accent: Color(0xFFBE123C),
  ),
  BoardTheme(
    id: 'space',
    name: 'Space',
    preview: '🪐',
    boardBg: Color(0xFF818CF8),
    cellBg: Color(0xFFEEF2FF),
    accent: Color(0xFF4C1D95),
    price: 8,
  ),
  BoardTheme(
    id: 'candy',
    name: 'Candy',
    preview: '🍭',
    boardBg: Color(0xFFF9A8D4),
    cellBg: Color(0xFFFDF2F8),
    accent: Color(0xFFBE185D),
    price: 8,
  ),
  BoardTheme(
    id: 'lava',
    name: 'Lava',
    preview: '🌋',
    boardBg: Color(0xFFFB923C),
    cellBg: Color(0xFFFFF7ED),
    accent: Color(0xFF9A3412),
    price: 12,
  ),
  BoardTheme(
    id: 'gold',
    name: 'Gold',
    preview: '👑',
    boardBg: Color(0xFFFDE047),
    cellBg: Color(0xFFFEFCE8),
    accent: Color(0xFF854D0E),
    price: 15,
  ),
];

class BoardFrame {
  final String id;
  final String name;
  final Color color;
  final double width;
  final int price; // 0 = free
  const BoardFrame({
    required this.id,
    required this.name,
    required this.color,
    this.width = 3,
    this.price = 0,
  });
}

const List<BoardFrame> kBoardFrames = [
  BoardFrame(id: 'bold', name: 'Bold', color: Colors.black, width: 4),
  BoardFrame(id: 'slim', name: 'Slim', color: Colors.black, width: 2),
  BoardFrame(id: 'mint', name: 'Mint', color: Color(0xFF16A34A), price: 6),
  BoardFrame(id: 'ocean', name: 'Ocean', color: Color(0xFF0284C7), price: 6),
  BoardFrame(id: 'coral', name: 'Coral', color: Color(0xFFE11D48), price: 8),
  BoardFrame(id: 'gold', name: 'Gold', color: Color(0xFFCA8A04), price: 10),
];

// ────────────────────────────────────────────────────────────────────────────
//  Quests
// ────────────────────────────────────────────────────────────────────────────
class QuestStatus {
  final String id;
  final String label;
  final int current;
  final int target;
  final int reward;
  final bool claimed;
  const QuestStatus({
    required this.id,
    required this.label,
    required this.current,
    required this.target,
    required this.reward,
    required this.claimed,
  });
  bool get done => current >= target;
}

/// Holds the profile-less game state shared across pages.
/// Firebase/profile/leaderboard live in [AppServices], which the store
/// re-broadcasts so any listener on the store sees service changes too.
class GameStore extends ChangeNotifier {
  final AppServices services;

  int _diamonds = kStartingDiamonds;
  final Set<String> _unlocked = {};
  final Set<String> _unlockedThemes = {};
  final Set<String> _unlockedFrames = {};
  String _themeId = kBoardThemes.first.id;
  String _frameId = kBoardFrames.first.id;

  int winStreak = 0;
  int questWins = 0;
  int questGames = 0;
  bool _streakReachedToday = false;
  String _questDate = '';
  String _bonusDate = '';
  final Set<String> _claimedToday = {};

  static const String _stateKey = 'ttt_state_v2';

  GameStore(this.services) {
    for (final item in kCatalog) {
      if (item.price == 0) _unlocked.add(item.emoji);
    }
    _unlockedThemes
        .addAll(kBoardThemes.where((t) => t.price == 0).map((t) => t.id));
    _unlockedFrames
        .addAll(kBoardFrames.where((f) => f.price == 0).map((f) => f.id));
    services.addListener(notifyListeners);
    _load();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  int get diamonds => _diamonds;
  bool get firebaseReady => services.firebaseReady;
  AppUserProfile? get user => services.user;
  String get displayName => services.displayName;

  Set<String> get unlocked => Set.unmodifiable(_unlocked);
  Set<String> get unlockedThemes => Set.unmodifiable(_unlockedThemes);
  Set<String> get unlockedFrames => Set.unmodifiable(_unlockedFrames);
  BoardTheme get theme =>
      kBoardThemes.firstWhere((t) => t.id == _themeId, orElse: () => kBoardThemes.first);
  BoardFrame get frame =>
      kBoardFrames.firstWhere((f) => f.id == _frameId, orElse: () => kBoardFrames.first);

  bool isUnlocked(String emoji) => _unlocked.contains(emoji);
  bool isThemeUnlocked(String id) => _unlockedThemes.contains(id);
  bool isFrameUnlocked(String id) => _unlockedFrames.contains(id);

  int priceOf(String emoji) {
    for (final item in kCatalog) {
      if (item.emoji == emoji) return item.price;
    }
    return 0;
  }

  int themePrice(String id) =>
      kBoardThemes.firstWhere((t) => t.id == id).price;
  int framePrice(String id) =>
      kBoardFrames.firstWhere((f) => f.id == id).price;

  // ── Streak / rewards ──────────────────────────────────────────────────────
  int get streakMultiplier => winStreak >= 7 ? 3 : (winStreak >= 3 ? 2 : 1);
  int get winReward => kWinReward * streakMultiplier;

  void addDiamonds(int amount) {
    _diamonds += amount;
    _save();
    notifyListeners();
  }

  // ── Shopping ──────────────────────────────────────────────────────────────
  bool buy(String emoji) {
    final price = priceOf(emoji);
    if (price == 0 || _unlocked.contains(emoji) || _diamonds < price) {
      return false;
    }
    _diamonds -= price;
    _unlocked.add(emoji);
    _save();
    notifyListeners();
    return true;
  }

  bool buyTheme(String id) {
    final price = themePrice(id);
    if (price == 0 || _unlockedThemes.contains(id) || _diamonds < price) {
      return false;
    }
    _diamonds -= price;
    _unlockedThemes.add(id);
    _save();
    notifyListeners();
    return true;
  }

  bool buyFrame(String id) {
    final price = framePrice(id);
    if (price == 0 || _unlockedFrames.contains(id) || _diamonds < price) {
      return false;
    }
    _diamonds -= price;
    _unlockedFrames.add(id);
    _save();
    notifyListeners();
    return true;
  }

  void selectTheme(String id) {
    if (_unlockedThemes.contains(id) && _themeId != id) {
      _themeId = id;
      _save();
      notifyListeners();
    }
  }

  void selectFrame(String id) {
    if (_unlockedFrames.contains(id) && _frameId != id) {
      _frameId = id;
      _save();
      notifyListeners();
    }
  }

  // ── Daily bonus + quests ──────────────────────────────────────────────────
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool get canClaimDaily => _bonusDate != _todayKey;

  int? claimDaily() {
    if (!canClaimDaily) return null;
    _bonusDate = _todayKey;
    _diamonds += kDailyBonus;
    _save();
    notifyListeners();
    return kDailyBonus;
  }

  List<QuestStatus> get quests => [
        QuestStatus(
          id: 'wins',
          label: 'WIN 3 MATCHES',
          current: questWins,
          target: 3,
          reward: kQuestWinReward,
          claimed: _claimedToday.contains('wins'),
        ),
        QuestStatus(
          id: 'plays',
          label: 'PLAY 5 MATCHES',
          current: questGames,
          target: 5,
          reward: kQuestPlayReward,
          claimed: _claimedToday.contains('plays'),
        ),
        QuestStatus(
          id: 'streak',
          label: 'HIT A 3-WIN STREAK',
          current: _streakReachedToday ? 1 : 0,
          target: 1,
          reward: kQuestStreakReward,
          claimed: _claimedToday.contains('streak'),
        ),
      ];

  int claimQuest(String id) {
    for (final q in quests) {
      if (q.id == id && q.done && !q.claimed) {
        _claimedToday.add(id);
        _diamonds += q.reward;
        _save();
        notifyListeners();
        return q.reward;
      }
    }
    return -1;
  }

  /// Records a finished round: updates streak/quests on this device and asks
  /// the services layer to update leaderboards.
  void reportRound({
    required bool p1Win,
    required bool p2Win,
    required bool playerWon,
  }) {
    winStreak = playerWon ? winStreak + 1 : 0;
    if (_questDate != _todayKey) {
      _questDate = _todayKey;
      questWins = 0;
      questGames = 0;
      _streakReachedToday = false;
      _claimedToday.clear();
    }
    questGames += 1;
    if (playerWon) {
      questWins += 1;
      if (winStreak >= 3) _streakReachedToday = true;
    }
    _save();
    services.recordResult(p1Win: p1Win, p2Win: p2Win);
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _diamonds = (j['diamonds'] as num?)?.toInt() ?? kStartingDiamonds;
      _unlocked.addAll((j['unlocked'] as List?)?.cast<String>() ?? const []);
      _unlockedThemes.addAll((j['themes'] as List?)?.cast<String>() ?? const []);
      _unlockedFrames.addAll((j['frames'] as List?)?.cast<String>() ?? const []);
      _themeId = (j['theme'] as String?) ?? _themeId;
      _frameId = (j['frame'] as String?) ?? _frameId;
      winStreak = (j['streak'] as num?)?.toInt() ?? 0;
      _questDate = (j['qd'] as String?) ?? '';
      questWins = (j['qw'] as num?)?.toInt() ?? 0;
      questGames = (j['qg'] as num?)?.toInt() ?? 0;
      _streakReachedToday = (j['qs'] as bool?) ?? false;
      _claimedToday.addAll((j['claimed'] as List?)?.cast<String>() ?? const []);
      _bonusDate = (j['bonus'] as String?) ?? '';
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _stateKey,
        jsonEncode({
          'diamonds': _diamonds,
          'unlocked': _unlocked.toList(),
          'themes': _unlockedThemes.toList(),
          'frames': _unlockedFrames.toList(),
          'theme': _themeId,
          'frame': _frameId,
          'streak': winStreak,
          'qd': _questDate,
          'qw': questWins,
          'qg': questGames,
          'qs': _streakReachedToday,
          'claimed': _claimedToday.toList(),
          'bonus': _bonusDate,
        }),
      );
    } catch (_) {}
  }
}