import 'dart:convert';

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
  final bool animated; // breath/pulse the board + winning cells
  const BoardTheme({
    required this.id,
    required this.name,
    required this.preview,
    required this.boardBg,
    required this.cellBg,
    required this.accent,
    this.price = 0,
    this.animated = false,
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
  BoardTheme(
    id: 'nebula',
    name: 'Nebula',
    preview: '🌌',
    boardBg: Color(0xFF312E81),
    cellBg: Color(0xFF4338CA),
    accent: Color(0xFFA78BFA),
    price: 20,
    animated: true,
  ),
  BoardTheme(
    id: 'neon',
    name: 'Neon',
    preview: '💜',
    boardBg: Color(0xFF0B0B0F),
    cellBg: Color(0xFF1F1F2E),
    accent: Color(0xFF22D3EE),
    price: 20,
    animated: true,
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

// ────────────────────────────────────────────────────────────────────────────
//  Achievements (permanent trophies + cosmetic unlocks)
// ────────────────────────────────────────────────────────────────────────────
class Achievement {
  final String id;
  final String icon;
  final String label;
  final String desc;
  final int target; // 0 = binary (shown as a check), else x/y progress
  const Achievement({
    required this.id,
    required this.icon,
    required this.label,
    required this.desc,
    this.target = 0,
  });
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_win',
    icon: '🎯',
    label: 'FIRST WIN',
    desc: 'WIN YOUR FIRST MATCH',
  ),
  Achievement(
    id: 'wins_10',
    icon: '🥉',
    label: '10 WINS',
    desc: 'WIN 10 MATCHES',
    target: 10,
  ),
  Achievement(
    id: 'wins_25',
    icon: '🥈',
    label: '25 WINS',
    desc: 'WIN 25 MATCHES',
    target: 25,
  ),
  Achievement(
    id: 'wins_50',
    icon: '🥇',
    label: '50 WINS',
    desc: 'WIN 50 MATCHES',
    target: 50,
  ),
  Achievement(
    id: 'streak_3',
    icon: '🔥',
    label: '3-IN-A-ROW',
    desc: 'WIN 3 MATCHES IN A ROW',
  ),
  Achievement(
    id: 'streak_7',
    icon: '🚀',
    label: '7-IN-A-ROW',
    desc: 'WIN 7 MATCHES IN A ROW',
  ),
  Achievement(
    id: 'games_20',
    icon: '🎮',
    label: '20 MATCHES',
    desc: 'PLAY 20 MATCHES',
    target: 20,
  ),
  Achievement(
    id: 'online_win',
    icon: '⚔️',
    label: 'ONLINE VICTORY',
    desc: 'WIN AN ONLINE MATCH',
  ),
  Achievement(
    id: 'collector',
    icon: '🛍️',
    label: 'COLLECTOR',
    desc: 'OWN 15 EMOJI',
    target: 15,
  ),
  Achievement(
    id: 'gems_200',
    icon: '💎',
    label: 'GEM HOUND',
    desc: 'EARN 200 GEMS TOTAL',
    target: 200,
  ),
  Achievement(
    id: 'day_7',
    icon: '📅',
    label: 'WEEK STREAK',
    desc: 'HIT A 7-DAY LOGIN STREAK',
  ),
];

class ProfileBanner {
  final String id;
  final String name;
  final Color color;
  final String achievementId; // required to unlock; '' = always available
  const ProfileBanner({
    required this.id,
    required this.name,
    required this.color,
    this.achievementId = '',
  });
}

const List<ProfileBanner> kProfileBanners = [
  ProfileBanner(
    id: 'sky',
    name: 'Sky',
    color: Color(0xFFBAE6FD),
  ),
  ProfileBanner(
    id: 'sunset',
    name: 'Sunset',
    color: Color(0xFFFDA4AF),
    achievementId: 'wins_10',
  ),
  ProfileBanner(
    id: 'ocean',
    name: 'Ocean',
    color: Color(0xFF60A5FA),
    achievementId: 'wins_25',
  ),
  ProfileBanner(
    id: 'canary',
    name: 'Canary',
    color: Color(0xFFFDE047),
    achievementId: 'streak_3',
  ),
  ProfileBanner(
    id: 'mint',
    name: 'Mint',
    color: Color(0xFF34D399),
    achievementId: 'wins_50',
  ),
  ProfileBanner(
    id: 'gold',
    name: 'Gold',
    color: Color(0xFFF59E0B),
    achievementId: 'gems_200',
  ),
];

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
  int _totalGemsEarned = 0;

  // Login streak calendar
  final Set<String> _logins = {};
  int _bestDayStreak = 0;
  int _onlineWins = 0;

  // Lifetime best win-in-a-row (for achievements).
  int _maxWinStreak = 0;

  // Lifetime stats from the active player's perspective (accurate W/D/G).
  int _playerGames = 0;
  int _playerWins = 0;
  int _playerDraws = 0;

  // Achievements + profile banner
  final Set<String> _unlockedAchievements = {};
  String _bannerId = kProfileBanners.first.id;

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

  // ── Login streak calendar ────────────────────────────────────────────────
  int get dayMultiplier => dayStreak >= 7 ? 3 : (dayStreak >= 3 ? 2 : 1);
  int get dayReward => todayBonus * dayMultiplier;

  /// Streak of consecutive days that had activity (a claim or a played
  /// round), counting back from today — or from yesterday while today is
  /// still pending so the run isn't shown as broken before tonight.
  int get dayStreak {
    if (_logins.isEmpty) return 0;
    var streak = 0;
    var cursor = DateTime.now();
    if (!_logins.contains(_keyOf(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (_logins.contains(_keyOf(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestDayStreak => _bestDayStreak;
  bool wasActiveOn(DateTime d) => _logins.contains(_keyOf(d));

  static String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _recordLogin() {
    _logins.add(_todayKey);
    final s = dayStreak;
    if (s > _bestDayStreak) _bestDayStreak = s;
    _evaluateAchievements();
    _save();
  }

  // ── Achievements / banners ───────────────────────────────────────────────
  bool isAchievementUnlocked(String id) => _unlockedAchievements.contains(id);
  int get unlockedAchievementCount => _unlockedAchievements.length;

  int progressFor(String id) => switch (id) {
        'wins_10' || 'wins_25' || 'wins_50' => _playerWins,
        'streak_3' || 'streak_7' => _maxWinStreak,
        'games_20' => _playerGames,
        'online_win' => _onlineWins,
        'collector' => _unlocked.length,
        'gems_200' => _totalGemsEarned,
        'day_7' => _bestDayStreak,
        _ => 0,
      };

  bool shouldUnlock(String id) {
    return switch (id) {
      'first_win' => _playerWins >= 1,
      'wins_10' => _playerWins >= 10,
      'wins_25' => _playerWins >= 25,
      'wins_50' => _playerWins >= 50,
      'streak_3' => _maxWinStreak >= 3,
      'streak_7' => _maxWinStreak >= 7,
      'games_20' => _playerGames >= 20,
      'online_win' => _onlineWins >= 1,
      'collector' => _unlocked.length >= 15,
      'gems_200' => _totalGemsEarned >= 200,
      'day_7' => _bestDayStreak >= 7,
      _ => false,
    };
  }

  void _evaluateAchievements() {
    var changed = false;
    for (final a in kAchievements) {
      if (!_unlockedAchievements.contains(a.id) && shouldUnlock(a.id)) {
        _unlockedAchievements.add(a.id);
        changed = true;
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  ProfileBanner get banner =>
      kProfileBanners.firstWhere((b) => b.id == _bannerId, orElse: () => kProfileBanners.first);
  bool isBannerUnlocked(String id) {
    final b = kProfileBanners.firstWhere((x) => x.id == id);
    return b.achievementId.isEmpty || _unlockedAchievements.contains(b.achievementId);
  }

  void selectBanner(String id) {
    if (isBannerUnlocked(id) && _bannerId != id) {
      _bannerId = id;
      _save();
      notifyListeners();
    }
  }

  // ── Streak / rewards ──────────────────────────────────────────────────────
  int get streakMultiplier => winStreak >= 7 ? 3 : (winStreak >= 3 ? 2 : 1);
  int get winReward => kWinReward * streakMultiplier;

  void addDiamonds(int amount) {
    if (amount <= 0) return;
    _diamonds += amount;
    _totalGemsEarned += amount;
    _evaluateAchievements();
    _save();
    notifyListeners();
  }

  int get totalGemsEarned => _totalGemsEarned;

  int get playerGames => _playerGames;
  int get playerWins => _playerWins;
  int get playerDraws => _playerDraws;

  // ── Shopping ──────────────────────────────────────────────────────────────
  bool buy(String emoji) {
    final price = priceOf(emoji);
    if (price == 0 || _unlocked.contains(emoji) || _diamonds < price) {
      return false;
    }
    _diamonds -= price;
    _unlocked.add(emoji);
    _evaluateAchievements();
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

  /// Today's daily bonus is deterministic so it stays the same all day (the
  /// button can show the exact amount before claiming) but changes daily.
  int get todayBonus {
    final seed = _todayKey.hashCode.abs();
    return 5 + (seed % 16); // 5–20💎
  }

  Future<int?> claimDaily() async {
    if (!canClaimDaily) return null;
    _bonusDate = _todayKey;
    _recordLogin();
    final amount = dayReward;
    addDiamonds(amount);
    await _save();
    return amount;
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

  Future<int> claimQuest(String id) async {
    for (final q in quests) {
      if (q.id == id && q.done && !q.claimed) {
        _claimedToday.add(id);
        addDiamonds(q.reward);
        await _save();
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
    bool online = false,
  }) {
    winStreak = playerWon ? winStreak + 1 : 0;
    if (winStreak > _maxWinStreak) _maxWinStreak = winStreak;
    if (online && playerWon) _onlineWins += 1;
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
    _playerGames += 1;
    if (playerWon) {
      _playerWins += 1;
    } else if (!p1Win && !p2Win) {
      _playerDraws += 1;
    }
    _recordLogin();
    _save();
    services.recordResult(p1Win: p1Win, p2Win: p2Win);
    _evaluateAchievements();
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
      _totalGemsEarned = (j['ge'] as num?)?.toInt() ?? 0;
      _logins.addAll((j['logins'] as List?)?.cast<String>() ?? const []);
      _bestDayStreak = (j['bs'] as num?)?.toInt() ?? 0;
      _maxWinStreak = (j['ms'] as num?)?.toInt() ?? 0;
      _onlineWins = (j['ow'] as num?)?.toInt() ?? 0;
      _playerGames = (j['pg'] as num?)?.toInt() ?? 0;
      _playerWins = (j['pw'] as num?)?.toInt() ?? 0;
      _playerDraws = (j['pd'] as num?)?.toInt() ?? 0;
      _unlockedAchievements
          .addAll((j['ach'] as List?)?.cast<String>() ?? const []);
      _bannerId = (j['banner'] as String?) ?? _bannerId;
    } catch (_) {}
    _evaluateAchievements();
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
          'ge': _totalGemsEarned,
          'logins': _logins.toList(),
          'bs': _bestDayStreak,
          'ms': _maxWinStreak,
          'ow': _onlineWins,
          'pg': _playerGames,
          'pw': _playerWins,
          'pd': _playerDraws,
          'ach': _unlockedAchievements.toList(),
          'banner': _bannerId,
        }),
      );
    } catch (_) {}
  }
}