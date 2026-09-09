import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ToEmoji());
}

class ToEmoji extends StatefulWidget {
  const ToEmoji({super.key});

  @override
  State<ToEmoji> createState() => _ToEmojiState();
}

class _ToEmojiState extends State<ToEmoji> {
  late final AppServices _services;
  late final GameStore _store;

  @override
  void initState() {
    super.initState();
    _services = AppServices();
    _store = GameStore(_services);
    _services.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'toemoji',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth <= 640) return child ?? const SizedBox.shrink();
            return Container(
              color: kBg,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox(
                  width: 640,
                  height: c.maxHeight,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'monospace',
        scaffoldBackgroundColor: kBg,
        visualDensity: VisualDensity.compact,
      ),
      home: HomePage(store: _store),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Home / onboarding
// ────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final GameStore store;
  const HomePage({super.key, required this.store});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _HomeContent(store: widget.store),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final GameStore store;
  const _HomeContent({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeaderRow(
          store: store,
          onProfile: () => pushBrutal(context, ProfilePage(store: store)),
          onStore: () => pushBrutal(context, StorePage(store: store)),
          onLeaderboard:
              () => pushBrutal(context, LeaderboardPage(store: store)),
          onAchievements:
              () => pushBrutal(context, AchievementsPage(store: store)),
        ),
        const SizedBox(height: 32),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text('🐶  VS  🐼', style: TextStyle(fontSize: 44)),
        ),
        const SizedBox(height: 28),
        BrutalCard(
          bg: kCanarySoft,
          padding: const EdgeInsets.all(16),
          child: const Text(
            'WINS EARN 💎 DIAMONDS. UNLOCK NEW EMOJI IN THE STORE. '
            'SIGN IN TO CHASE THE ONLINE LEADERBOARD.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionDivider(),
        const SizedBox(height: 16),
        const Text(
          'play',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          label: '🎮 CUSTOM GAME',
          active: false,
          onTap: () => pushBrutal(context, CustomGamePage(store: store)),
        ),
        const SizedBox(height: 10),
        if (store.user != null)
          _ModeCard(
            label: '⚔ ONLINE PVP',
            active: false,
            onTap: () => pushBrutal(context, OnlineLobbyPage(store: store)),
          ),
        const SizedBox(height: 16),
        _DailyQuestsCard(store: store),
      ],
    );
  }
}

class _DailyQuestsCard extends StatelessWidget {
  final GameStore store;
  const _DailyQuestsCard({required this.store});

  void _toast(BuildContext context, String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final signedIn = store.user != null;
        final bonusReady = store.canClaimDaily;
        final allDone =
            !bonusReady && store.quests.every((q) => q.claimed);
        return BrutalCard(
          bg: Colors.white,
          shadow: kShadowSm,
          padding: const EdgeInsets.all(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            alignment: Alignment.topCenter,
            curve: Curves.easeOut,
            child:
                allDone
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '🎁 DAILY & QUESTS ALL DONE · SEE YOU TOMORROW ✓',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                !bonusReady
                                    ? '🎁 DAILY BONUS CLAIMED'
                                    : (signedIn
                                        ? (store.dayMultiplier > 1
                                            ? '🎁 DAILY BONUS READY · x${store.dayMultiplier} STREAK'
                                            : '🎁 DAILY BONUS READY')
                                        : '🔒 SIGN IN TO CLAIM DAILY BONUS'),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            BrutalButton(
                              label: !bonusReady
                                  ? '✓ DONE'
                                  : (signedIn
                                      ? 'CLAIM +${store.dayReward}💎'
                                      : 'LOG IN'),
                              bg: bonusReady ? kCanary : Colors.white,
                              enabled: bonusReady,
                              fontSize: 11,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              onPressed: !bonusReady
                                  ? null
                                  : (signedIn
                                      ? () async {
                                        final got = await store.claimDaily();
                                        if (got != null && context.mounted) {
                                          _toast(
                                            context,
                                            '+$got💎 DAILY BONUS!',
                                            kMint,
                                          );
                                        }
                                      }
                                      : () => pushBrutal(
                                          context,
                                          SignInPage(store: store),
                                        )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SectionDivider(),
                        const SizedBox(height: 10),
                        const Text(
                          'DAILY QUESTS',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final q in store.quests) ...[
                          _QuestRow(
                            store: store,
                            quest: q,
                            signedIn: signedIn,
                            onToast: _toast,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
          ),
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  final GameStore store;
  final QuestStatus quest;
  final bool signedIn;
  final void Function(BuildContext, String, Color) onToast;
  const _QuestRow({
    required this.store,
    required this.quest,
    required this.signedIn,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        quest.target == 0
            ? 1.0
            : (quest.current / quest.target).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.label,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kBlack, width: 1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(color: quest.done ? kMint : kCanary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (quest.claimed)
          const Text('✓', style: TextStyle(fontSize: 18))
        else
          BrutalButton(
            label: quest.done
                ? (signedIn ? '+${quest.reward}💎' : 'LOG IN')
                : '${quest.current}/${quest.target}',
            bg: quest.done ? kMint : Colors.white,
            enabled: quest.done,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: !quest.done
                ? null
                : (signedIn
                    ? () async {
                      final got = await store.claimQuest(quest.id);
                      if (got > 0 && context.mounted) {
                        onToast(context, 'QUEST COMPLETE +$got💎', kMint);
                      }
                    }
                    : () =>
                          pushBrutal(context, SignInPage(store: store))),
          ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final GameStore store;
  const _StreakCard({required this.store});

  static const _wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final today = DateTime.now();
        final streak = store.dayStreak;
        final mult = store.dayMultiplier;
        return BrutalCard(
          bg: Colors.white,
          shadow: kShadowSm,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '📅 DAY STREAK CALENDAR',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    '🔥 ${streak == 0 ? 'NO STREAK' : '$streak DAY${streak == 1 ? '' : 'S'}'}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                mult > 1
                    ? 'DAILY BONUS ×$mult · CLAIM THE BONUS EACH DAY TO KEEP IT ALIVE'
                    : 'EARN ×2 BONUS AT 3 DAYS · ×3 AT 7 DAYS',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 13; i >= 0; i--)
                    Expanded(
                      child: _DayCell(
                        day: today.subtract(Duration(days: i)),
                        active: store.wasActiveOn(
                          today.subtract(Duration(days: i)),
                        ),
                        isToday: i == 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool active;
  final bool isToday;
  const _DayCell({required this.day, required this.active, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _StreakCard._wd[day.weekday - 1],
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: active ? kMint : Colors.white,
              border: Border.all(
                color: isToday ? kBlack : const Color(0xFFB5B5B5),
                width: isToday ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                active ? '✓' : '${day.day}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeCard({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? kMint : Colors.white,
          border: Border.all(color: kBlack, width: 2),
          boxShadow:
              active
                  ? const [BoxShadow(color: kBlack, offset: Offset(4, 4))]
                  : kShadowNone,
        ),
        child: Row(
          children: [
            Text(
              active ? '◉' : '○',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: kBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Achievements (permanent trophies → cosmetic unlocks)
// ────────────────────────────────────────────────────────────────────────────
class AchievementsPage extends StatelessWidget {
  final GameStore store;
  const AchievementsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          BrutalIconButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'ACHIEVEMENTS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Text(
                            '${store.unlockedAchievementCount}/${kAchievements.length}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BrutalCard(
                        bg: kCanarySoft,
                        child: const Text(
                          'PERMANENT TROPHIES. UNLOCKED ONES CAN ALSO '
                          'UNLOCK PROFILE BANNER COLORS.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kAchievements.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 190,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.05,
                            ),
                        itemBuilder: (context, i) {
                          final a = kAchievements[i];
                          final unlocked = store.isAchievementUnlocked(a.id);
                          final cur = store
                              .progressFor(a.id)
                              .clamp(0, a.target == 0 ? 1 : a.target);
                          return BrutalCard(
                            bg: unlocked ? kMint : Colors.white,
                            shadow: kShadowSm,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: unlocked ? 1 : 0.45,
                                  child: Text(
                                    a.icon,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.desc,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (unlocked)
                                  const Text(
                                    'UNLOCKED ✓',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                else if (a.target > 0) ...[
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: kBlack,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: a.target == 0
                                          ? 0
                                          : (cur / a.target).clamp(0.0, 1.0),
                                      child: Container(color: kCanary),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$cur/${a.target}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'LOCKED 🔒',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'PROFILE BANNERS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BrutalCard(
                        bg: Colors.white,
                        shadow: kShadowSm,
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final b in kProfileBanners)
                              Container(
                                width: 110,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: b.color,
                                  border: Border.all(color: kBlack, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      store.isBannerUnlocked(b.id)
                                          ? '✓ ${b.name}'
                                          : '🔒 ${b.name}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (!store.isBannerUnlocked(b.id)) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'UNLOCK ${_bannerRequirement(b.achievementId)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _bannerRequirement(String achievementId) {
    for (final a in kAchievements) {
      if (a.id == achievementId) return a.label;
    }
    return '';
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Custom game: mode + blitz + ranked setup
// ────────────────────────────────────────────────────────────────────────────
class CustomGamePage extends StatelessWidget {
  final GameStore store;
  const CustomGamePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _CustomGameBody(store: store),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomGameBody extends StatefulWidget {
  final GameStore store;
  const _CustomGameBody({required this.store});

  @override
  State<_CustomGameBody> createState() => _CustomGameBodyState();
}

class _CustomGameBodyState extends State<_CustomGameBody> {
  GameMode _mode = GameMode.twoPlayer;
  int _blitz = 0;
  bool _ranked = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BrutalIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'CUSTOM GAME',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                DiamondBadge(diamonds: widget.store.diamonds),
              ],
            ),
            const SizedBox(height: 16),
            ScoreBar(store: widget.store),
            const SizedBox(height: 16),
            const SectionDivider(),
            const SizedBox(height: 16),
            const Text(
              'choose mode',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            for (final m in GameMode.values) ...[
              _ModeCard(
                label: m.label,
                active: _mode == m,
                onTap: () => setState(() => _mode = m),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            BrutalCard(
              bg: kSky,
              shadow: kShadowSm,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '⏱ BLITZ CLOCK',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in const [0, 15, 30, 60])
                        _OptionChip(
                          active: _blitz == s,
                          label: s == 0 ? 'OFF' : '${s}s',
                          onTap: () => setState(() => _blitz = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '⚔ RANKED',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const Text(
                        'x2💎 REWARD',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _OptionChip(
                        active: _ranked,
                        label: _ranked ? 'ON' : 'OFF',
                        onTap: () => setState(() => _ranked = !_ranked),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BrutalButton(
              label: 'NEXT → PICK FIGHTERS',
              bg: kCanary,
              onPressed:
                  () => pushBrutal(
                    context,
                    EmojiSelectionPage(
                      store: widget.store,
                      mode: _mode,
                      blitzSeconds: _blitz,
                      ranked: _ranked,
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Emoji selection
// ────────────────────────────────────────────────────────────────────────────
class EmojiSelectionPage extends StatelessWidget {
  final GameStore store;
  final GameMode mode;
  final int blitzSeconds;
  final bool ranked;
  const EmojiSelectionPage({
    super.key,
    required this.store,
    required this.mode,
    this.blitzSeconds = 0,
    this.ranked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _EmojiSelectionBody(
                store: store,
                mode: mode,
                blitzSeconds: blitzSeconds,
                ranked: ranked,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiSelectionBody extends StatefulWidget {
  final GameStore store;
  final GameMode mode;
  final int blitzSeconds;
  final bool ranked;
  const _EmojiSelectionBody({
    required this.store,
    required this.mode,
    required this.blitzSeconds,
    required this.ranked,
  });

  @override
  State<_EmojiSelectionBody> createState() => _EmojiSelectionBodyState();
}

class _EmojiSelectionBodyState extends State<_EmojiSelectionBody> {
  late String _p1 = '🐶';
  late String _p2 = '🐼';

  @override
  Widget build(BuildContext context) {
    final vsAi = widget.mode.isAi;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BrutalIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PICK YOUR FIGHTERS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                DiamondBadge(diamonds: widget.store.diamonds),
              ],
            ),
            const SizedBox(height: 16),
            ScoreBar(store: widget.store),
            const SizedBox(height: 16),
            BrutalCard(
              bg: _p1Color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _PickerHeader(
                label: 'PLAYER 1',
                selected: _p1,
                onRandom: () => setState(() => _p1 = _randomFree(widget.store, except: _p2)),
              ),
            ),
            const SizedBox(height: 8),
            _EmojiGrid(
              store: widget.store,
              selected: _p1,
              takenEmoji: vsAi ? null : _p2,
              onPick: (e) => setState(() {
                _p1 = e;
                if (!vsAi && _p2 == e) {
                  _p2 = _nextFree(widget.store, except: e);
                }
              }),
            ),
            const SizedBox(height: 14),
            BrutalCard(
              bg: vsAi ? kMint : _p2Color,
              shadow: vsAi ? kShadowNone : kShadow,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child:
                  vsAi
                      ? const _PickerHeader(
                        label: 'CPU OPPONENT',
                        selected: kAiEmoji,
                        hint: '🤖 NO STOCK',
                      )
                      : _PickerHeader(
                        label: 'PLAYER 2',
                        selected: _p2,
                        onRandom:
                            () => setState(() => _p2 = _randomFree(widget.store, except: _p1)),
                      ),
            ),
            if (!vsAi) ...[
              const SizedBox(height: 8),
              _EmojiGrid(
                store: widget.store,
                selected: _p2,
                takenEmoji: _p1,
                onPick: (e) => setState(() {
                  _p2 = e;
                  if (e == _p1) {
                    _p1 = _nextFree(widget.store, except: e);
                  }
                }),
              ),
            ],
            const SizedBox(height: 18),
            BrutalButton(
              label: widget.mode.label,
              onPressed:
                  () => pushBrutal(
                    context,
                    GamePage(
                      store: widget.store,
                      mode: widget.mode,
                      p1Emoji: _p1,
                      p2Emoji: widget.mode.isAi ? kAiEmoji : _p2,
                      blitzSeconds: widget.blitzSeconds,
                      ranked: widget.ranked,
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  String _nextFree(GameStore store, {required String except}) {
    for (final item in kCatalog) {
      if (store.isUnlocked(item.emoji) &&
          item.emoji != except &&
          item.emoji != kAiEmoji) {
        return item.emoji;
      }
    }
    return kCatalog.first.emoji;
  }

  String _randomFree(GameStore store, {required String except}) {
    final free = kCatalog
        .where(
          (i) => store.isUnlocked(i.emoji) && i.emoji != except && i.emoji != kAiEmoji,
        )
        .toList();
    if (free.isEmpty) return _nextFree(store, except: except);
    return free[math.Random().nextInt(free.length)].emoji;
  }

  Color get _p1Color => kLavender;
  Color get _p2Color => kSky;
}

class _PickerHeader extends StatelessWidget {
  final String label;
  final String selected;
  final VoidCallback? onRandom;
  final String? hint;
  const _PickerHeader({
    required this.label,
    required this.selected,
    this.onRandom,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        if (hint != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hint!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(selected, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRandom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: kBlack, width: 2),
                    ),
                    child: const Text('🎲', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _OptionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kMint : Colors.white,
          border: Border.all(color: kBlack, width: 2),
          boxShadow: active ? kShadowNone : kShadowSm,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final GameStore store;
  final String selected;
  final String? takenEmoji;
  final ValueChanged<String> onPick;
  const _EmojiGrid({
    required this.store,
    required this.selected,
    this.takenEmoji,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kCatalog.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 92,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, i) {
        final item = kCatalog[i];
        final unlocked = store.isUnlocked(item.emoji);
        return EmojiTile(
          item: item,
          selected: selected == item.emoji,
          unlocked: unlocked,
          taken: item.emoji == takenEmoji,
          onTap: () => onPick(item.emoji),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Game
// ────────────────────────────────────────────────────────────────────────────
const List<List<int>> _winLines = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

class GamePage extends StatefulWidget {
  final GameStore store;
  final GameMode mode;
  final String p1Emoji;
  final String p2Emoji;
  final int blitzSeconds;
  final bool ranked;
  const GamePage({
    super.key,
    required this.store,
    required this.mode,
    required this.p1Emoji,
    required this.p2Emoji,
    this.blitzSeconds = 0,
    this.ranked = false,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late List<String?> _board = List.filled(9, null);
  late String _current = widget.p1Emoji;
  bool _over = false;
  bool _reported = false;
  List<int>? _winningLine;
  Timer? _aiTimer;
  Timer? _tick;
  int? _secondsLeft;
  final List<int> _moves = [];

  bool get _isAiTurn => widget.mode.isAi && _current == widget.p2Emoji;

  @override
  void initState() {
    super.initState();
    _startTurnClock();
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _reset() {
    _aiTimer?.cancel();
    _tick?.cancel();
    setState(() {
      _board = List.filled(9, null);
      _current = widget.p1Emoji;
      _over = false;
      _reported = false;
      _winningLine = null;
      _moves.clear();
    });
    _startTurnClock();
  }

  void _startTurnClock() {
    _tick?.cancel();
    if (widget.blitzSeconds <= 0 || _over || _isAiTurn) {
      _secondsLeft = null;
      return;
    }
    _secondsLeft = widget.blitzSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _over || widget.blitzSeconds <= 0) {
        _tick?.cancel();
        return;
      }
      setState(() => _secondsLeft = (_secondsLeft ?? 1) - 1);
      if (_secondsLeft == 0) {
        _tick?.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    if (_over) return;
    final timedOutP1 = _current == widget.p1Emoji;
    setState(() => _over = true);
    _finishRound(p1Won: !timedOutP1, p2Won: timedOutP1);
  }

  Future<void> _onCell(int i) async {
    if (_over || _board[i] != null || _isAiTurn) return;
    _move(i, _current);
  }

  void _move(int i, String mark) {
    _moves.add(i);
    setState(() {
      _board[i] = mark;
      _current = mark == widget.p1Emoji ? widget.p2Emoji : widget.p1Emoji;
    });
    _checkEnd();
    if (!_over && _isAiTurn) {
      _aiTimer?.cancel();
      _aiTimer = Timer(const Duration(milliseconds: 420), _aiMove);
    } else if (!_over) {
      _startTurnClock();
    }
  }

  void _aiMove() {
    if (!mounted || _over) return;
    final empties = [
      for (int i = 0; i < 9; i++)
        if (_board[i] == null) i,
    ];
    if (empties.isEmpty) return;
    final pick =
        widget.mode == GameMode.vsAiEasy
            ? empties[math.Random().nextInt(empties.length)]
            : _bestAiMove(empties);
    _move(pick, widget.p2Emoji);
  }

  int _bestAiMove(List<int> empties) {
    int bestScore = -1000;
    int best = empties.first;
    for (final i in empties) {
      _board[i] = widget.p2Emoji;
      final score = _minimax(false);
      _board[i] = null;
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  int _minimax(bool aiTurn) {
    final w = _winner();
    if (w == widget.p2Emoji) return 10;
    if (w == widget.p1Emoji) return -10;
    if (!_board.contains(null)) return 0;
    int best = aiTurn ? -1000 : 1000;
    for (int i = 0; i < 9; i++) {
      if (_board[i] != null) continue;
      _board[i] = aiTurn ? widget.p2Emoji : widget.p1Emoji;
      final score = _minimax(!aiTurn);
      _board[i] = null;
      best = aiTurn ? math.max(best, score) : math.min(best, score);
    }
    return best;
  }

  String? _winner() {
    for (final line in _winLines) {
      final a = _board[line[0]];
      if (a != null && a == _board[line[1]] && a == _board[line[2]]) {
        return a;
      }
    }
    return null;
  }

  void _checkEnd() {
    final w = _winner();
    if (w != null) {
      final line = _winLines.firstWhere(
        (l) =>
            _board[l[0]] != null &&
            _board[l[0]] == _board[l[1]] &&
            _board[l[0]] == _board[l[2]],
      );
      final p1Won = w == widget.p1Emoji;
      final p2Won = w == widget.p2Emoji;
      setState(() {
        _over = true;
        _winningLine = line;
      });
      _finishRound(p1Won: p1Won, p2Won: p2Won);
    } else if (!_board.contains(null)) {
      setState(() => _over = true);
      _finishRound(p1Won: false, p2Won: false);
    }
  }

  void _finishRound({required bool p1Won, required bool p2Won}) {
    if (_reported) return;
    _reported = true;
    final playerWon = widget.mode.isAi ? p1Won : p1Won || p2Won;
    widget.store.reportRound(p1Win: p1Won, p2Win: p2Won, playerWon: playerWon);
    final reward =
        playerWon ? widget.store.winReward * (widget.ranked ? 2 : 1) : 0;
    if (reward > 0) widget.store.addDiamonds(reward);
    widget.store.services.recordMatch(
      mode: widget.mode.label,
      p1Emoji: widget.p1Emoji,
      p2Emoji: widget.p2Emoji,
      p1Name: widget.store.displayName,
      p2Name: widget.mode.isAi ? 'CPU' : widget.store.displayName,
      winner: p1Won ? 'p1' : (p2Won ? 'p2' : 'draw'),
      moves: List.of(_moves),
    );
    _showResult(
      p1Won: p1Won,
      p2Won: p2Won,
      rewardEarned: reward,
      streak: widget.store.winStreak,
      mult: widget.store.streakMultiplier,
    );
  }

  void _showResult({
    required bool p1Won,
    required bool p2Won,
    required int rewardEarned,
    required int streak,
    required int mult,
  }) {
    final isDraw = !p1Won && !p2Won;
    if (!isDraw) showEmojiConfetti(context);
    String title;
    String emoji;
    if (isDraw) {
      title = 'DRAW';
      emoji = '🤝';
    } else if (p1Won) {
      title = 'PLAYER 1 WINS';
      emoji = widget.p1Emoji;
    } else {
      title = 'CPU WINS';
      emoji = widget.p2Emoji;
    }
    showDialog(
      context: context,
      barrierColor: kBlack.withValues(alpha: 0.6),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: BrutalCard(
              bg: kCanary,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (rewardEarned > 0) ...[
                    Text(
                      '+$rewardEarned💎',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (streak >= 2) ...[
                      const SizedBox(height: 2),
                      Text(
                        '🔥 $streak-WIN STREAK (x$mult)',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrutalButton(
                          label: 'REMATCH',
                          onPressed: () {
                            Navigator.pop(context);
                            _reset();
                          },
                        ),
                        const SizedBox(width: 10),
                        BrutalButton(
                          label: 'MENU',
                          bg: Colors.white,
                          fontSize: 15,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _aiTimer?.cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BrutalIconButton(
                          icon: Icons.arrow_back,
                          onPressed: () {
                            _aiTimer?.cancel();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.mode.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        DiamondBadge(diamonds: widget.store.diamonds),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TurnStrip(
                      p1: widget.p1Emoji,
                      p2: widget.p2Emoji,
                      current: _current,
                      isAiMode: widget.mode.isAi,
                      timeLeft: _secondsLeft,
                      blitzSeconds: widget.blitzSeconds,
                      ranked: widget.ranked,
                    ),
                    const SizedBox(height: 16),
                    _Board(
                      board: _board,
                      winningLine: _winningLine,
                      onTap: _onCell,
                      theme: widget.store.theme,
                      frame: widget.store.frame,
                    ),
                    const SizedBox(height: 16),
                    BrutalButton(
                      label: 'NEW GAME',
                      bg: Colors.white,
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnStrip extends StatelessWidget {
  final String p1;
  final String p2;
  final String current;
  final bool isAiMode;
  final int? timeLeft;
  final int blitzSeconds;
  final bool ranked;
  const _TurnStrip({
    required this.p1,
    required this.p2,
    required this.current,
    required this.isAiMode,
    this.timeLeft,
    this.blitzSeconds = 0,
    this.ranked = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == p1;
    final label =
        isAiMode && active ? 'YOUR TURN' : '${active ? 'P1' : 'P2'} TURN';
    return BrutalCard(
      bg: active ? kMint : kCoral,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(child: Text(p1, style: const TextStyle(fontSize: 26))),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$label${ranked ? ' · ⚔' : ''}'
                '${blitzSeconds > 0 ? ' · ⏱ ${timeLeft ?? blitzSeconds}' : ''}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(child: Text(p2, style: const TextStyle(fontSize: 26))),
        ],
      ),
    );
  }
}

class _Board extends StatefulWidget {
  final List<String?> board;
  final List<int>? winningLine;
  final ValueChanged<int> onTap;
  final BoardTheme theme;
  final BoardFrame frame;
  const _Board({
    required this.board,
    required this.winningLine,
    required this.onTap,
    required this.theme,
    required this.frame,
  });

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _shouldAnimate =>
      widget.theme.animated || (widget.winningLine != null);

  @override
  void initState() {
    super.initState();
    if (_shouldAnimate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Board old) {
    super.didUpdateWidget(old);
    if (_shouldAnimate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!_shouldAnimate && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse =
        0.5 + 0.5 * math.sin(_c.value * 2 * math.pi); // 0..1 breathing wave
    final bg =
        widget.theme.animated
            ? Color.lerp(
                widget.theme.boardBg,
                Color.lerp(widget.theme.boardBg, Colors.black, 0.35) ??
                    widget.theme.boardBg,
                pulse,
              ) ??
                widget.theme.boardBg
            : widget.theme.boardBg;
    return Container(
      padding: EdgeInsets.all(widget.frame.width),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: widget.frame.color, width: widget.frame.width),
        boxShadow: const [BoxShadow(color: kBlack, offset: Offset(6, 6))],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, i) {
            final mark = widget.board[i];
            final isWin = widget.winningLine?.contains(i) ?? false;
            return GestureDetector(
              key: ValueKey('cell-$i'),
              onTap: () => widget.onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color:
                      isWin
                          ? widget.theme.accent
                          : (mark == null
                              ? widget.theme.cellBg
                              : gradientColor(mark)),
                  border: Border.all(color: kBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(color: kBlack, offset: Offset(4, 4)),
                  ],
                ),
                child: Center(
                  child: isWin
                      ? ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.14).animate(
                            CurvedAnimation(
                              parent: _c,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Text(
                            mark ?? '',
                            style: const TextStyle(fontSize: 40),
                          ),
                        )
                      : Text(mark ?? '', style: const TextStyle(fontSize: 40)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Store
// ────────────────────────────────────────────────────────────────────────────
class StorePage extends StatelessWidget {
  final GameStore store;
  const StorePage({super.key, required this.store});

  void _buy(BuildContext context, String emoji) {
    final ok = store.buy(emoji);
    final item = kCatalog.firstWhere((i) => i.emoji == emoji);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? kMint : kCoral,
        content: Text(
          ok ? 'UNLOCKED ${item.emoji}!' : 'NEED ${item.price}💎',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  void _tapTheme(BuildContext context, BoardTheme t) {
    if (store.isThemeUnlocked(t.id)) {
      store.selectTheme(t.id);
      _toast(context, 'THEME: ${t.name}', kMint);
    } else if (store.diamonds >= t.price) {
      store.buyTheme(t.id);
      store.selectTheme(t.id);
      _toast(context, 'UNLOCKED ${t.name} (-${t.price}💎)', kMint);
    } else {
      _toast(context, 'NEED ${t.price}💎', kCoral);
    }
  }

  void _tapFrame(BuildContext context, BoardFrame f) {
    if (store.isFrameUnlocked(f.id)) {
      store.selectFrame(f.id);
      _toast(context, 'FRAME: ${f.name}', kMint);
    } else if (store.diamonds >= f.price) {
      store.buyFrame(f.id);
      store.selectFrame(f.id);
      _toast(context, 'UNLOCKED ${f.name} (-${f.price}💎)', kMint);
    } else {
      _toast(context, 'NEED ${f.price}💎', kCoral);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          BrutalIconButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'EMOJI STORE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          DiamondBadge(diamonds: store.diamonds),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BrutalCard(
                        bg: kCanarySoft,
                        child: const Text(
                          'WIN MATCHES TO EARN 💎. SPEND THEM HERE ON '
                          'FIGHTERS, BOARD BACKGROUNDS & FRAMES.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BACKGROUNDS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kBoardThemes.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 160,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.9,
                            ),
                        itemBuilder: (context, i) {
                          final t = kBoardThemes[i];
                          final owned = store.isThemeUnlocked(t.id);
                          return _ThemeTile(
                            preview: t.preview,
                            bg: t.boardBg,
                            cellBg: t.cellBg,
                            accent: t.accent,
                            name: t.name,
                            price: t.price,
                            owned: owned,
                            selected: store.theme.id == t.id,
                            diamonds: store.diamonds,
                            onTap: () => _tapTheme(context, t),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'FRAMES',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kBoardFrames.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 140,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.9,
                            ),
                        itemBuilder: (context, i) {
                          final f = kBoardFrames[i];
                          final owned = store.isFrameUnlocked(f.id);
                          return _FrameTile(
                            color: f.color,
                            width: f.width,
                            name: f.name,
                            price: f.price,
                            owned: owned,
                            selected: store.frame.id == f.id,
                            diamonds: store.diamonds,
                            onTap: () => _tapFrame(context, f),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'FIGHTERS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kCatalog.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 150,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                            ),
                        itemBuilder: (context, i) {
                          final item = kCatalog[i];
                          final unlocked = store.isUnlocked(item.emoji);
                          return _StoreTile(
                            item: item,
                            unlocked: unlocked,
                            diamonds: store.diamonds,
                            onBuy: () => _buy(context, item.emoji),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final EmojiItem item;
  final bool unlocked;
  final int diamonds;
  final VoidCallback onBuy;
  const _StoreTile({
    required this.item,
    required this.unlocked,
    required this.diamonds,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final affordable = !unlocked && diamonds >= item.price;
    return BrutalCard(
      bg: unlocked ? kMint : Colors.white,
      shadow: kShadowSm,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (unlocked)
            const Text(
              'OWNED ✓',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            AffordButton(
              affordable: affordable,
              label: '${item.price}💎',
              onPressed: onBuy,
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Sign in
// ────────────────────────────────────────────────────────────────────────────
class SignInPage extends StatefulWidget {
  final GameStore store;
  const SignInPage({super.key, required this.store});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrutalIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SIGN IN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '👤',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 24),
                  if (!store.firebaseReady)
                    BrutalCard(
                      bg: kCoral,
                      child: const Text(
                        'FIREBASE ISN\'T CONFIGURED YET.\n'
                        'SEE THE README FOR THE 3-MIN SETUP '
                        '(ADD google-services.json + GOOGLE CLIENT-ID).\n\n'
                        'UNTIL THEN YOU CAN STILL PLAY LOCALLY — '
                        'SCORES ARE SAVED ON THIS DEVICE.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (store.user != null)
                    BrutalCard(
                      bg: kMint,
                      child: Column(
                        children: [
                          Text(
                            'SIGNED IN AS',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store.user!.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    BrutalCard(
                      bg: kSky,
                      child: const Text(
                        'CONNECT A GOOGLE ACCOUNT TO SYNC YOUR '
                        'WINS TO THE GLOBAL LEADERBOARD.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (store.services.lastError != null && store.user == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BrutalCard(
                        bg: kCoral,
                        child: Text(
                          store.services.lastError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else if (store.firebaseReady && store.user == null)
                    BrutalButton(
                      label: '▶ SIGN IN WITH GOOGLE',
                      bg: kCanary,
                      onPressed: () async {
                        setState(() => _busy = true);
                        final ok = await store.services.signInWithGoogle();
                        final err = store.services.lastError;
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: ok ? kMint : kCoral,
                            content: Text(
                              ok
                                  ? 'WELCOME!'
                                  : err ?? 'SIGN-IN FAILED / CANCELLED',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                color: kBlack,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else if (store.firebaseReady && store.user != null)
                    BrutalButton(
                      label: 'SIGN OUT',
                      bg: Colors.white,
                      onPressed: () => store.services.signOut(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Leaderboard
// ────────────────────────────────────────────────────────────────────────────
class LeaderboardPage extends StatefulWidget {
  final GameStore store;
  const LeaderboardPage({super.key, required this.store});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<LeaderboardEntry>> _future;
  String? _lastUid;
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _lastUid = widget.store.user?.uid;
    widget.store.addListener(_onStoreChanged);
    _future = widget.store.services.fetchLeaderboard(period: _period);
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    final uid = widget.store.user?.uid;
    if (uid != _lastUid) {
      _lastUid = uid;
      if (mounted) _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _future = widget.store.services.fetchLeaderboard(period: _period);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BrutalIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'LEADERBOARD',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      BrutalIconButton(
                        icon: Icons.refresh,
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final p in LeaderboardPeriod.values)
                            _OptionChip(
                              active: _period == p,
                              label:
                                  p == LeaderboardPeriod.weekly
                                      ? 'WEEKLY'
                                      : 'MONTHLY',
                              onTap: () {
                                setState(() => _period = p);
                                _refresh();
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!widget.store.firebaseReady)
                    BrutalCard(
                      bg: kCoral,
                      child: const Text(
                        'ONLINE BOARD NEEDS GOOGLE SIGN-IN + FIREBASE.\n'
                        'SHOWING THIS DEVICE\'S TOTALS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    BrutalCard(
                      bg: kSky,
                      child: const Text(
                        'GLOBAL TOP WINS · LIVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (widget.store.services.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BrutalCard(
                        bg: kCoral,
                        child: Text(
                          widget.store.services.lastError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<LeaderboardEntry>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const BrutalCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      final entries = snap.data ?? const [];
                      if (entries.isEmpty) {
                        return const BrutalCard(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'NO RESULTS YET. GO WIN SOME GAMES!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (int i = 0; i < entries.length; i++)
                            _RankRow(
                              rank: i + 1,
                              entry: entries[i],
                              isMe:
                                  widget.store.user != null &&
                                  widget.store.user!.uid == entries[i].uid &&
                                  entries[i].uid.isNotEmpty,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  const _RankRow({required this.rank, required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final medal =
        rank == 1
            ? '🥇'
            : rank == 2
            ? '🥈'
            : rank == 3
            ? '🥉'
            : '$rank';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrutalCard(
        bg: isMe ? kCanary : Colors.white,
        shadow: kShadowSm,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                medal,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${entry.wins} W',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.games} G',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String preview;
  final Color bg;
  final Color cellBg;
  final Color accent;
  final String name;
  final int price;
  final bool owned;
  final bool selected;
  final int diamonds;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.preview,
    required this.bg,
    required this.cellBg,
    required this.accent,
    required this.name,
    required this.price,
    required this.owned,
    required this.selected,
    required this.diamonds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrutalCard(
        bg: selected ? kCanary : Colors.white,
        shadow: kShadowSm,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: kBlack, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(2),
                    width: 9,
                    height: 9,
                    color: cellBg,
                  ),
                  Container(
                    margin: const EdgeInsets.all(2),
                    width: 9,
                    height: 9,
                    color: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$preview ${name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (owned)
              const Text(
                'OWNED ✓',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              AffordButton(
                affordable: diamonds >= price,
                label: '$price💎',
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _FrameTile extends StatelessWidget {
  final Color color;
  final double width;
  final String name;
  final int price;
  final bool owned;
  final bool selected;
  final int diamonds;
  final VoidCallback onTap;
  const _FrameTile({
    required this.color,
    required this.width,
    required this.name,
    required this.price,
    required this.owned,
    required this.selected,
    required this.diamonds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrutalCard(
        bg: selected ? kCanary : Colors.white,
        shadow: kShadowSm,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: width),
              ),
              child: const Center(
                child: Text(
                  '□',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (owned)
              const Text(
                'OWNED ✓',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              AffordButton(
                affordable: diamonds >= price,
                label: '$price💎',
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Profile (nickname + avatar sticker)
// ────────────────────────────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  final GameStore store;
  const ProfilePage({super.key, required this.store});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name;
  late Future<FriendData> _friends;
  String _avatar = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store.services.nickname ?? '');
    _avatar = widget.store.services.avatar ?? '';
    _friends = widget.store.services.fetchFriends();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toast(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  Future<void> _accept(String uid) async {
    final ok = await widget.store.services.acceptFriend(uid);
    if (!mounted) return;
    _toast(ok ? 'FRIEND ADDED ✓' : 'COULD\'T ACCEPT', ok ? kMint : kCoral);
    setState(() => _friends = widget.store.services.fetchFriends());
  }

  Future<void> _decline(String uid) async {
    await widget.store.services.declineFriend(uid);
    if (!mounted) return;
    setState(() => _friends = widget.store.services.fetchFriends());
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          BrutalIconButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'PROFILE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          if (store.user != null)
                            const Text('⚡', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BrutalCard(
                        bg: store.banner.color,
                        shadow: kShadow,
                        child: Column(
                          children: [
                            Text(
                              store.services.avatar ??
                                  (store.user != null ? '⭕' : '👤'),
                              style: const TextStyle(fontSize: 64),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              store.displayName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              store.user?.email ?? 'LOCAL PLAYER',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (store.user == null) ...[
                        const SizedBox(height: 14),
                        BrutalCard(
                          bg: kCanarySoft,
                          shadow: kShadowSm,
                          child: Column(
                            children: [
                              const Text(
                                'SIGN IN TO CLAIM 💎 BONUSES & CHASE THE '
                                'LEADERBOARD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              BrutalButton(
                                label: 'SIGN IN',
                                bg: kCanary,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                onPressed: () =>
                                    pushBrutal(context, SignInPage(store: store)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        BrutalButton(
                          label: 'SIGN OUT',
                          bg: Colors.white,
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          onPressed: () async {
                            await store.services.signOut();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _ProfileStatsCard(store: store),
                      const SizedBox(height: 14),
                      _StreakCard(store: store),
                      const SizedBox(height: 18),
                      const Text(
                        'PROFILE BANNER COLOR',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BrutalCard(
                        bg: store.banner.color,
                        shadow: kShadowSm,
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final b in kProfileBanners)
                              GestureDetector(
                                onTap: store.isBannerUnlocked(b.id)
                                    ? () => store.selectBanner(b.id)
                                    : null,
                                child: Container(
                                  width: 52,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: b.color,
                                    border: Border.all(
                                      color: kBlack,
                                      width: store.banner.id == b.id ? 3 : 1.5,
                                    ),
                                    boxShadow: store.banner.id == b.id
                                        ? kShadowSm
                                        : kShadowNone,
                                  ),
                                  child: Center(
                                    child: Text(
                                      store.isBannerUnlocked(b.id) ? '✓' : '🔒',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'NICKNAME (SHOWN ON LEADERBOARD)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: kBlack, width: 2),
                        ),
                        child: TextField(
                          controller: _name,
                          maxLength: 16,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'YOUR NAME',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      BrutalButton(
                        label: 'SAVE NAME',
                        bg: kMint,
                        onPressed: () {
                          store.services.setProfile(name: _name.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: kMint,
                              content: const Text(
                                'SAVED!',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  color: kBlack,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'CHOOSE AVATAR STICKER',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: store.unlocked.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 72,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemBuilder: (context, i) {
                          final emoji = store.unlocked.toList()[i];
                          final active = emoji == _avatar;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _avatar = emoji);
                              store.services.setProfile(avatar: emoji);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: active ? kCanary : Colors.white,
                                border: Border.all(
                                  color: kBlack,
                                  width: active ? 3 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'FRIENDS',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          BrutalIconButton(
                            icon: Icons.refresh,
                            onPressed:
                                () => setState(
                                  () =>
                                      _friends =
                                          widget.store.services.fetchFriends(),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<FriendData>(
                        future: _friends,
                        builder: (context, snap) {
                          if (!store.services.online) {
                            return const BrutalCard(
                              bg: Color(0xFFE5E5E5),
                              child: Padding(
                                padding: EdgeInsets.all(14),
                                child: Text(
                                  'SIGN IN TO CONNECT WITH FRIENDS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          }
                          final data = snap.data;
                          if (data == null) {
                            return const BrutalCard(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }
                          final rows = <Widget>[];
                          if (data.incoming.isNotEmpty) {
                            rows.add(
                              _friendHeader(
                                'REQUESTS IN (${data.incoming.length})',
                              ),
                            );
                            for (final f in data.incoming) {
                              rows.add(
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FriendTile(
                                        friend: f,
                                        pending: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    BrutalButton(
                                      label: 'ACCEPT',
                                      bg: kMint,
                                      fontSize: 11,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      onPressed: () => _accept(f.uid),
                                    ),
                                    const SizedBox(width: 6),
                                    BrutalButton(
                                      label: '✕',
                                      bg: Colors.white,
                                      fontSize: 12,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 9,
                                      ),
                                      onPressed: () => _decline(f.uid),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          rows.add(
                            _friendHeader('FRIENDS (${data.friends.length})'),
                          );
                          if (data.friends.isEmpty) {
                            rows.add(
                              const BrutalCard(
                                bg: Colors.white,
                                shadow: kShadowNone,
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'NO FRIENDS YET.\nPLAY ONLINE AND ADD YOUR RIVALS AFTER A MATCH.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            for (final f in data.friends) {
                              rows.add(
                                _FriendTile(
                                  friend: f,
                                  onTap: () => pushBrutal(
                                    context,
                                    FriendProfilePage(
                                      services: widget.store.services,
                                      friend: f,
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                          if (data.outgoing.isNotEmpty) {
                            rows.add(
                              _friendHeader(
                                'PENDING OUT (${data.outgoing.length})',
                              ),
                            );
                            for (final f in data.outgoing) {
                              rows.add(_FriendTile(friend: f, pending: true));
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rows,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Profile stats + friends helpers
// ────────────────────────────────────────────────────────────────────────────
class _ProfileStatsCard extends StatelessWidget {
  final GameStore store;
  const _ProfileStatsCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final matches = store.playerGames;
    final wins = store.playerWins;
    final draws = store.playerDraws;
    final winPct = matches == 0 ? 0 : (wins * 100 ~/ matches);
    return BrutalCard(
      bg: Colors.white,
      shadow: kShadowSm,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProfileStat(icon: '🏆', value: '$winPct%', label: 'WIN %'),
              const SizedBox(width: 8),
              _ProfileStat(icon: '🎮', value: '$matches', label: 'MATCHES'),
              const SizedBox(width: 8),
              _ProfileStat(
                icon: '💎',
                value: '${store.totalGemsEarned}',
                label: 'GEMS EARNED',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SectionDivider(),
          const SizedBox(height: 6),
          Text(
            '$wins WINS · $draws DRAWS',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBlack, width: 1.5),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _friendHeader(String label) => Padding(
  padding: const EdgeInsets.only(top: 10, bottom: 6),
  child: Text(
    label,
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2,
    ),
  ),
);

class FriendProfilePage extends StatefulWidget {
  final AppServices services;
  final FriendEntry friend;
  const FriendProfilePage({
    super.key,
    required this.services,
    required this.friend,
  });

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  late Future<LeaderboardEntry?> _stats;

  @override
  void initState() {
    super.initState();
    _stats = widget.services.fetchUserStats(widget.friend.uid);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BrutalIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'PROFILE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Text('🤝', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  BrutalCard(
                    bg: kSky,
                    shadow: kShadow,
                    child: Column(
                      children: [
                        Text(f.emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 8),
                        Text(
                          f.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'FRIEND',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<LeaderboardEntry?>(
                    future: _stats,
                    builder: (context, snap) {
                      final entry = snap.data;
                      final wins = entry?.wins ?? 0;
                      final games = entry?.games ?? 0;
                      final pct = games == 0 ? 0 : (wins * 100 ~/ games);
                      return BrutalCard(
                        bg: Colors.white,
                        shadow: kShadowSm,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'THIS WEEK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ProfileStat(icon: '🏆', value: '$pct%', label: 'WIN %'),
                                const SizedBox(width: 8),
                                _ProfileStat(icon: '🎮', value: '$games', label: 'GAMES'),
                                const SizedBox(width: 8),
                                _ProfileStat(icon: '⚡', value: '$wins', label: 'WINS'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendEntry friend;
  final bool pending;
  final VoidCallback? onTap;
  const _FriendTile({required this.friend, this.pending = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrutalCard(
        bg: pending ? const Color(0xFFF3F4F6) : Colors.white,
        shadow: kShadowNone,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Opacity(
          opacity: pending ? 0.6 : 1,
          child: Row(
            children: [
              Text(friend.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (pending)
                const Text('⏳', style: TextStyle(fontSize: 14))
              else
                const Text('›', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Recent matches feed + replay
// ────────────────────────────────────────────────────────────────────────────
class MatchFeedPage extends StatefulWidget {
  final GameStore store;
  const MatchFeedPage({super.key, required this.store});

  @override
  State<MatchFeedPage> createState() => _MatchFeedPageState();
}

class _MatchFeedPageState extends State<MatchFeedPage> {
  late Future<List<MatchRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.store.services.fetchRecentMatches();
  }

  void _refresh() {
    setState(() {
      _future = widget.store.services.fetchRecentMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BrutalIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'RECENT MATCHES',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      BrutalIconButton(
                        icon: Icons.refresh,
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<MatchRecord>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const BrutalCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      final matches = snap.data ?? const [];
                      if (matches.isEmpty) {
                        return const BrutalCard(
                          bg: kCanarySoft,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'NO MATCHES YET. GO PLAY SOME GAMES!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final m in matches)
                            _MatchCard(
                              match: m,
                              onTap:
                                  () =>
                                      pushBrutal(context, ReplayPage(match: m)),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchRecord match;
  final VoidCallback onTap;
  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final winLabel =
        match.winner == 'p1'
            ? '🏆 ${match.p1Name}'
            : match.winner == 'p2'
            ? '🏆 ${match.p2Name}'
            : '🤝 DRAW';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: BrutalCard(
          bg: Colors.white,
          shadow: kShadowSm,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    match.mode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '▶ REPLAY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${match.p1Emoji} ${match.p1Name}  VS  '
                  '${match.p2Emoji} ${match.p2Name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                winLabel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReplayPage extends StatefulWidget {
  final MatchRecord match;
  const ReplayPage({super.key, required this.match});

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  int _step = 0;
  bool _playing = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String?> _boardAt(int step) {
    final board = List<String?>.filled(9, null);
    for (int i = 0; i < step; i++) {
      final idx = widget.match.moves[i];
      if (idx >= 0 && idx < 9) {
        board[idx] = i.isEven ? widget.match.p1Emoji : widget.match.p2Emoji;
      }
    }
    return board;
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        if (!mounted) return;
        if (_step >= widget.match.moves.length) {
          _timer?.cancel();
          setState(() => _playing = false);
          return;
        }
        setState(() => _step += 1);
      });
    } else {
      _timer?.cancel();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moves = widget.match.moves;
    final atEnd = _step >= moves.length;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BrutalIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'REPLAY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BrutalCard(
                    bg: kSky,
                    padding: const EdgeInsets.all(12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.match.p1Emoji} ${widget.match.p1Name}  VS  '
                        '${widget.match.p2Emoji} ${widget.match.p2Name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Board(
                    board: _boardAt(_step),
                    winningLine: null,
                    onTap: (_) {},
                    theme: kBoardThemes.first,
                    frame: kBoardFrames.first,
                  ),
                  const SizedBox(height: 16),
                  BrutalCard(
                    bg: kCanarySoft,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            atEnd
                                ? 'GAME OVER'
                                : 'MOVE ${_step + 1} / ${moves.length}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _ReplayBtn(
                          icon: '◀',
                          onTap:
                              _step > 0
                                  ? () => setState(() => _step -= 1)
                                  : null,
                        ),
                        const SizedBox(width: 6),
                        _ReplayBtn(
                          icon: _playing ? '⏸' : '▶',
                          onTap: (atEnd && !_playing) ? _reset : _togglePlay,
                        ),
                        const SizedBox(width: 6),
                        _ReplayBtn(
                          icon: '▶',
                          onTap:
                              (!atEnd && !_playing)
                                  ? () => setState(() => _step += 1)
                                  : (_playing
                                      ? null
                                      : (_step == 0 ? null : _reset)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplayBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  const _ReplayBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BrutalButton(
      label: icon,
      onPressed: onTap,
      bg: Colors.white,
      fontSize: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Online PvP
// ────────────────────────────────────────────────────────────────────────────
class OnlineLobbyPage extends StatefulWidget {
  final GameStore store;
  const OnlineLobbyPage({super.key, required this.store});

  @override
  State<OnlineLobbyPage> createState() => _OnlineLobbyPageState();
}

class _OnlineLobbyPageState extends State<OnlineLobbyPage> {
  late Future<List<LobbyGame>> _future;
  String _myEmoji = '🐶';
  bool _private = false;
  final TextEditingController _code = TextEditingController();

  static const _codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  String _generateRoomCode() {
    final r = math.Random();
    return List.generate(5, (_) => _codeChars[r.nextInt(_codeChars.length)])
        .join();
  }

  @override
  void initState() {
    super.initState();
    _future = widget.store.services.fetchOpenGames();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = widget.store.services.fetchOpenGames();
    });
  }

  Future<void> _create() async {
    final code = _private ? _generateRoomCode() : null;
    final id = await widget.store.services.createOnlineGame(
      hostEmoji: _myEmoji,
      hostName: widget.store.displayName,
      roomCode: code,
    );
    if (id == null || !mounted) {
      if (mounted) _fail("COULDN'T CREATE GAME.");
      return;
    }
    if (code != null) {
      await _showInviteDialog(code);
      if (!mounted) return;
    }
    _openGame(id, isHost: true, myEmoji: _myEmoji, roomCode: code);
  }

  Future<void> _showInviteDialog(String code) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: kBlack.withValues(alpha: 0.6),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: BrutalCard(
          bg: kLavender,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'PRIVATE ROOM CREATED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'SHARE THIS CODE — FRIENDS ENTER IT IN THE LOBBY.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 14),
              BrutalButton(
                label: 'COPY CODE',
                bg: kCanary,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      backgroundColor: kMint,
                      content: Text(
                        'CODE COPIED ✓',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          color: kBlack,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              BrutalButton(
                label: 'START GAME →',
                bg: Colors.white,
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinByCode() async {
    final (id, used) = await widget.store.services.joinOnlineGameByCode(
      _code.text,
      guestEmoji: _myEmoji,
      guestName: widget.store.displayName,
    );
    if (id == null || used == null || !mounted) {
      if (mounted) _fail('NO OPEN PRIVATE GAME WITH THAT CODE.');
      return;
    }
    if (used != _myEmoji) _sayFighterChanged(used);
    _openGame(id, isHost: false, myEmoji: used);
  }

  Future<void> _join(String id) async {
    final used = await widget.store.services.joinOnlineGame(
      id,
      guestEmoji: _myEmoji,
      guestName: widget.store.displayName,
    );
    if (used == null || !mounted) {
      if (mounted) _fail('GAME IS GONE / TAKEN.');
      return;
    }
    if (used != _myEmoji) _sayFighterChanged(used);
    _openGame(id, isHost: false, myEmoji: used);
  }

  void _sayFighterChanged(String emoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kLavender,
        duration: const Duration(seconds: 3),
        content: Text(
          'THAT FIGHTER IS TAKEN — YOU PLAY AS $emoji',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  void _openGame(
    String id, {
    required bool isHost,
    required String myEmoji,
    String? roomCode,
  }) {
    pushBrutal(
      context,
      OnlineGamePage(
        store: widget.store,
        docId: id,
        isHost: isHost,
        myEmoji: myEmoji,
        roomCode: roomCode,
      ),
    );
  }

  void _fail(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kCoral,
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.store.services;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BrutalIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'ONLINE PVP',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      BrutalIconButton(
                        icon: Icons.refresh,
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!services.online) ...[
                    BrutalCard(
                      bg: kCoral,
                      child: const Text(
                        'SIGN IN WITH GOOGLE TO PLAY ONLINE.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else ...[
                    BrutalCard(
                      bg: kSky,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'YOUR FIGHTER',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final emoji in _pickEmojis())
                                _OptionChip(
                                  active: _myEmoji == emoji,
                                  label: emoji,
                                  onTap: () => setState(() => _myEmoji = emoji),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BrutalCard(
                      bg: kLavender,
                      shadow: kShadowSm,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '🔒 PRIVATE ROOM',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              _OptionChip(
                                active: _private,
                                label: _private ? 'ON' : 'OFF',
                                onTap: () =>
                                    setState(() => _private = !_private),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'GENERATE AN INVITE CODE — FRIENDS JOIN THROUGH '
                            'THE LOBBY INSTEAD OF RANDOM MATCHMAKING.',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'JOIN WITH A CODE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: kBlack, width: 2),
                                  ),
                                  child: TextField(
                                    controller: _code,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    maxLength: 5,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: 'CODE',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              BrutalButton(
                                label: 'JOIN',
                                bg: kMint,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                onPressed: _code.text.trim().length == 5
                                    ? _joinByCode
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BrutalButton(
                      label: _private ? '＋ CREATE PRIVATE GAME' : '＋ CREATE GAME',
                      bg: kCanary,
                      onPressed: _create,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OPEN GAMES',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<LobbyGame>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const BrutalCard(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }
                        final games = snap.data ?? const [];
                        if (games.isEmpty) {
                          return const BrutalCard(
                            bg: kCanarySoft,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'NO OPEN GAMES. CREATE ONE AND WAIT FOR A RIVAL!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final g in games)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BrutalCard(
                                  bg: Colors.white,
                                  shadow: kShadowSm,
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Text(
                                        g.hostEmoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          g.hostName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      BrutalButton(
                                        label: 'JOIN',
                                        bg: kMint,
                                        fontSize: 13,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        onPressed: () => _join(g.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _pickEmojis() {
    final base = widget.store.unlocked.toList();
    return base.take(6).toList();
  }
}

class OnlineGamePage extends StatefulWidget {
  final GameStore store;
  final String docId;
  final bool isHost;
  final String myEmoji;
  final String? roomCode;
  const OnlineGamePage({
    super.key,
    required this.store,
    required this.docId,
    required this.isHost,
    required this.myEmoji,
    this.roomCode,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  List<String?> _board = List.filled(9, null);
  String? _oppEmoji;
  String? _oppName;
  String? _hostUid;
  String? _guestUid;
  String? _turn;
  String _status = 'open';
  String _winner = '';
  String _rematchReq = '';
  bool _reported = false;
  bool _myProposed = false;
  bool _incomingShown = false;
  bool _roundOver = false;
  bool _closedShown = false;
  final List<BuildContext> _openDialogs = [];
  StreamSubscription? _sub;

  void _closeAllDialogs() {
    for (final c in _openDialogs.reversed) {
      if (c.mounted) Navigator.of(c).pop();
    }
    _openDialogs.clear();
  }

  String get _mySide => widget.isHost ? 'host' : 'guest';
  String? get _oppUid => widget.isHost ? _guestUid : _hostUid;
  bool get _open => _status == 'open';
  bool get _playing => _status == 'playing';
  bool get _myTurn => _playing && _turn == widget.myEmoji;

  @override
  void initState() {
    super.initState();
    _sub = widget.store.services
        .watchOnlineGame(widget.docId)
        .listen(_onUpdate, onError: (_) {});
    widget.store.services.fetchOnlineGame(widget.docId).then((data) {
      if (data != null) _onUpdate(data);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onUpdate(Map<String, dynamic>? data) {
    if (!mounted || data == null) return;
    final wasDone = _status == 'done';
    final prevReq = _rematchReq;
    setState(() {
      _board = List<String?>.from(
        (data['board'] as List?)?.map((e) => e as String?) ??
            List.filled(9, null),
      );
      _turn = data['turn'] as String?;
      _status = (data['status'] as String?) ?? 'open';
      _winner = (data['winner'] as String?) ?? '';
      _rematchReq = (data['rematch'] as String?) ?? '';
      _hostUid = data['hostUid'] as String?;
      _guestUid = data['guestUid'] as String?;
      final guestE = data['guestEmoji'] as String?;
      _oppEmoji = widget.isHost ? guestE : (data['hostEmoji'] as String?);
      _oppName =
          widget.isHost
              ? (data['guestName'] as String?)
              : (data['hostName'] as String?);
      if (_status == 'done' && !_reported) {
        _reported = true;
        _settle();
      }
    });

    if (_status == 'done' && !_roundOver) {
      _roundOver = true;
      _schedule(() {
        if (!mounted || _status != 'done') return;
        final req = _rematchReq;
        if (_incomingShown) return;
        if (req == _mySide || _myProposed) {
          setState(() => _myProposed = true);
          return;
        }
        if (req.isNotEmpty) {
          _closeAllDialogs();
          _showIncomingRematchDialog();
          return;
        }
        _showEndDialog();
      });
    } else if (_status == 'done' &&
        !_incomingShown &&
        !_myProposed &&
        _rematchReq.isNotEmpty &&
        _rematchReq != _mySide) {
      // Rival proposed a rematch while we had just finished.
      _closeAllDialogs();
      _showIncomingRematchDialog();
    } else if (_status == 'closed' && !_closedShown) {
      // The rival left — surface this even if the end/rematch dialog is open.
      _closedShown = true;
      _closeAllDialogs();
      _schedule(_showClosedDialog);
    } else if (_status == 'playing' && wasDone) {
      // A rematch round just started: reset local state + swap dialogs.
      _roundOver = false;
      _reported = false;
      _myProposed = false;
      _incomingShown = false;
      _closedShown = false;
      _closeAllDialogs();
      _schedule(() {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: kMint,
            content: Text(
              '🔥 REMATCH! GOOD LUCK',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                color: kBlack,
              ),
            ),
          ),
        );
      });
    } else if (_roundOver && prevReq == _mySide && _rematchReq.isEmpty) {
      // My proposal was cleared: the rival declined.
      _myProposed = false;
      _schedule(() {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: kCoral,
            content: Text(
              'RIVAL DECLINED THE REMATCH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      });
    }
  }

  void _schedule(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fn();
    });
  }

  void _settle() {
    final win = _winner;
    final iWon = win.isNotEmpty && win == widget.myEmoji;
    widget.store.reportRound(
      p1Win: iWon,
      p2Win: win.isNotEmpty && !iWon,
      playerWon: iWon,
      online: true,
    );
    if (iWon) widget.store.addDiamonds(widget.store.winReward);
    widget.store.services.recordMatch(
      id: widget.docId,
      mode: '2P ONLINE',
      p1Emoji: widget.isHost ? widget.myEmoji : (_oppEmoji ?? '🐶'),
      p2Emoji: widget.isHost ? (_oppEmoji ?? '🐼') : widget.myEmoji,
      p1Name: widget.isHost ? widget.store.displayName : (_oppName ?? 'Rival'),
      p2Name: widget.isHost ? (_oppName ?? 'Rival') : widget.store.displayName,
      winner: win.isEmpty ? 'draw' : (iWon ? 'p1' : 'p2'),
      moves: const [],
    );
  }

  void _onCell(int i) {
    if (!_myTurn || _board[i] != null) return;
    widget.store.services.playOnlineMove(widget.docId, i, widget.myEmoji);
    setState(() {
      _board[i] = widget.myEmoji;
      _turn = _oppEmoji;
    });
  }

  void _leave() {
    widget.store.services.closeOnlineGame(widget.docId);
    Navigator.pop(context);
  }

  Future<void> _requestRematch() async {
    final r = await widget.store.services.requestRematch(widget.docId, _mySide);
    if (!mounted) return;
    if (r == 'proposed') {
      setState(() => _myProposed = true);
    } else if (r != 'started') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'CAN\'T REQUEST A REMATCH',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
  }

  void _showClosedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: kBlack.withValues(alpha: 0.6),
      builder: (c) {
        _openDialogs
          ..clear()
          ..add(c);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BrutalCard(
            bg: kCoral,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❌', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  'RIVAL LEFT THE MATCH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                BrutalButton(
                  label: 'OK',
                  bg: Colors.white,
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showIncomingRematchDialog() {
    _incomingShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: kBlack.withValues(alpha: 0.6),
      builder: (c) {
        _openDialogs
          ..clear()
          ..add(c);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BrutalCard(
            bg: kMint,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  'REMATCH REQUEST!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_oppName ?? 'RIVAL'} WANTS ANOTHER ROUND',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrutalButton(
                        label: 'ACCEPT',
                        bg: kCanary,
                        onPressed: () {
                          _incomingShown = false;
                          Navigator.pop(c);
                          _requestRematch();
                        },
                      ),
                      const SizedBox(width: 10),
                      BrutalButton(
                        label: 'DECLINE',
                        bg: Colors.white,
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        onPressed: () {
                          _incomingShown = false;
                          Navigator.pop(c);
                          widget.store.services.declineRematch(widget.docId);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEndDialog() {
    final iWon = _winner.isNotEmpty && _winner == widget.myEmoji;
    if (iWon) showEmojiConfetti(context);
    final title =
        iWon ? 'YOU WIN!' : (_winner.isNotEmpty ? 'YOU LOSE' : 'DRAW');
    final mark = _winner.isNotEmpty ? _winner : '🤝';
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: kBlack.withValues(alpha: 0.6),
      builder: (context) {
        _openDialogs
          ..clear()
          ..add(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BrutalCard(
            bg: iWon ? kMint : (_winner.isNotEmpty ? kCoral : kCanary),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mark, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (iWon) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+${widget.store.winReward}💎',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_canAddFriend) ...[
                  BrutalButton(
                    label: '➕ ADD FRIEND',
                    bg: kCanary,
                    fontSize: 15,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _addFriend();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrutalButton(
                        label: 'REMATCH',
                        onPressed: () {
                          Navigator.pop(context);
                          _requestRematch();
                        },
                      ),
                      const SizedBox(width: 10),
                      BrutalButton(
                        label: 'LEAVE',
                        bg: Colors.white,
                        fontSize: 15,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _leave();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _canAddFriend =>
      widget.store.services.online &&
      _oppUid != null &&
      _oppUid != widget.store.services.user?.uid;

  Future<void> _addFriend() async {
    final uid = _oppUid;
    if (uid == null) return;
    final ok = await widget.store.services.sendFriendRequest(
      uid,
      name: _oppName ?? 'Rival',
      emoji: _oppEmoji ?? '🐶',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? kMint : kCoral,
        content: Text(
          ok ? 'FRIEND REQUEST SENT ✓' : 'COULD\'T SEND — SIGN IN FIRST',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: kBlack,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oppE = _oppEmoji ?? '❓';
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _sub?.cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BrutalIconButton(
                          icon: Icons.arrow_back,
                          onPressed: _leave,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ONLINE BATTLE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        DiamondBadge(diamonds: widget.store.diamonds),
                      ],
                    ),
                    if (widget.roomCode != null) ...[
                      const SizedBox(height: 12),
                      BrutalCard(
                        bg: kLavender,
                        shadow: kShadowSm,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '🔒 ROOM ${widget.roomCode}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            BrutalButton(
                              label: 'COPY CODE',
                              bg: kCanary,
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.roomCode!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: kMint,
                                    content: Text(
                                      'CODE COPIED ✓',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        color: kBlack,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _TurnStrip(
                      p1: widget.isHost ? widget.myEmoji : oppE,
                      p2: widget.isHost ? oppE : widget.myEmoji,
                      current: _playing ? (_turn ?? widget.myEmoji) : '',
                      isAiMode: false,
                    ),
                    const SizedBox(height: 8),
                    if (_open)
                      BrutalCard(
                        bg: kCanarySoft,
                        child: const Text(
                          '⏳ WAITING FOR A RIVAL TO JOIN…',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else if (_status == 'done')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BrutalCard(
                            bg: kMint,
                            child: Text(
                              _winner.isNotEmpty && _winner == widget.myEmoji
                                  ? '🏆 YOU WIN! +${widget.store.winReward}💎'
                                  : (_winner.isNotEmpty ? 'YOU LOSE' : 'DRAW'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (_myProposed || _rematchReq == _mySide) ...[
                            const SizedBox(height: 8),
                            BrutalCard(
                              bg: kCanarySoft,
                              child: const Text(
                                '⏳ WAITING FOR RIVAL TO ACCEPT REMATCH…',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_status == 'closed')
                      BrutalCard(
                        bg: kCoral,
                        child: const Text(
                          '❌ MATCH CLOSED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else if (!_myTurn)
                      BrutalCard(
                        bg: kCoral,
                        child: Text(
                          '${_oppName ?? 'RIVAL'} IS THINKING…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _Board(
                      board: _board,
                      winningLine:
                          _winner.isNotEmpty
                              ? _winningLineOf(_board, _winner)
                              : null,
                      onTap: _onCell,
                      theme: widget.store.theme,
                      frame: widget.store.frame,
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.myEmoji} ${widget.store.displayName}  VS  '
                        '$oppE ${_oppName ?? '…'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BrutalButton(
                      label: 'LEAVE MATCH',
                      bg: kCoral,
                      onPressed: _leave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<int>? _winningLineOf(List<String?> board, String mark) {
  for (final line in _winLines) {
    if (board[line[0]] == mark &&
        board[line[1]] == mark &&
        board[line[2]] == mark) {
      return line;
    }
  }
  return null;
}

// ────────────────────────────────────────────────────────────────────────────
//  Win-confetti emoji burst
// ────────────────────────────────────────────────────────────────────────────
class _ConfettiParticle {
  final String emoji;
  final double angle; // radians from screen center
  final double distance;
  final double size;
  final double start; // 0..1 when this particle takes off
  final int spin;
  _ConfettiParticle({
    required this.emoji,
    required this.angle,
    required this.distance,
    required this.size,
    required this.start,
    required this.spin,
  });
}

class EmojiConfettiOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const EmojiConfettiOverlay({super.key, required this.onDone});

  @override
  State<EmojiConfettiOverlay> createState() => _EmojiConfettiOverlayState();
}

class _EmojiConfettiOverlayState extends State<EmojiConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _emojis = ['🎉', '🎊', '✨', '💎', '⭐', '🌈', '🎈', '🥳'];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final List<_ConfettiParticle> _parts;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
    _parts = List.generate(26, (_) {
      return _ConfettiParticle(
        emoji: _emojis[rand.nextInt(_emojis.length)],
        angle: rand.nextDouble() * 2 * math.pi,
        distance: 70 + rand.nextDouble() * 160,
        size: 18 + rand.nextDouble() * 20,
        start: rand.nextDouble() * 0.25,
        spin: rand.nextBool() ? 1 : -1,
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            children: [
              for (final p in _parts)
                Builder(
                  builder: (context) {
                    final raw = (_c.value - p.start) / (1 - p.start);
                    final t = raw.clamp(0.0, 1.0);
                    final eased = Curves.easeOutCubic.transform(t);
                    final dx = math.cos(p.angle) * p.distance * eased;
                    final dy = math.sin(p.angle) * p.distance * eased +
                        70 * eased * eased;
                    final fade =
                        t > 0.7 ? (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;
                    return Positioned(
                      left: cx + dx - p.size / 2,
                      top: cy + dy - p.size / 2,
                      child: Opacity(
                        opacity: fade,
                        child: Transform.rotate(
                          angle: p.spin * eased * math.pi * 2,
                          child: Text(
                            p.emoji,
                            style: TextStyle(fontSize: p.size),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

void showEmojiConfetti(BuildContext context) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        EmojiConfettiOverlay(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}
