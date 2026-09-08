import 'package:flutter/foundation.dart';

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

const int kWinReward = 5; // diamonds earned per win
const int kStartingDiamonds = 6;
const String kAiEmoji = '🤖';

/// Holds the profile-less game state shared across pages.
/// Firebase/profile/leaderboard live in [AppServices], which the store
/// re-broadcasts so any listener on the store sees service changes too.
class GameStore extends ChangeNotifier {
  final AppServices services;

  int _diamonds = kStartingDiamonds;
  final Set<String> _unlocked = {};

  GameStore(this.services) {
    for (final item in kCatalog) {
      if (item.price == 0) _unlocked.add(item.emoji);
    }
    services.addListener(notifyListeners);
  }

  int get diamonds => _diamonds;
  bool get firebaseReady => services.firebaseReady;
  AppUserProfile? get user => services.user;

  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  bool isUnlocked(String emoji) => _unlocked.contains(emoji);

  int priceOf(String emoji) {
    for (final item in kCatalog) {
      if (item.emoji == emoji) return item.price;
    }
    return 0;
  }

  void addDiamonds(int amount) {
    _diamonds += amount;
    notifyListeners();
  }

  bool buy(String emoji) {
    final price = priceOf(emoji);
    if (price == 0 || _unlocked.contains(emoji) || _diamonds < price) {
      return false;
    }
    _diamonds -= price;
    _unlocked.add(emoji);
    notifyListeners();
    return true;
  }

  /// Records a finished round into the leaderboard service.
  void reportRound({required bool p1Win, required bool p2Win}) {
    services.recordResult(
      p1Win: p1Win,
      p2Win: p2Win,
      name: user?.name ?? 'You',
      photoUrl: user?.photoUrl,
    );
  }

  @override
  void dispose() {
    services.removeListener(notifyListeners);
    super.dispose();
  }
}