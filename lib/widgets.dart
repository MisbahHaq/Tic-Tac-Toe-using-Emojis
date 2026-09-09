import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';

/// Header with diamonds + profile/store/leaderboard/achievements shortcuts.
class HeaderRow extends StatelessWidget {
  final GameStore store;
  final VoidCallback onProfile;
  final VoidCallback onStore;
  final VoidCallback onLeaderboard;
  final VoidCallback onAchievements;
  const HeaderRow({
    super.key,
    required this.store,
    required this.onProfile,
    required this.onStore,
    required this.onLeaderboard,
    required this.onAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        DiamondBadge(diamonds: store.diamonds),
        const SizedBox(width: 6),
        BrutalIconButton(icon: Icons.person_outline, onPressed: onProfile),
        const SizedBox(width: 6),
        BrutalIconButton(icon: Icons.store_outlined, onPressed: onStore),
        const SizedBox(width: 6),
        BrutalIconButton(
          icon: Icons.emoji_events_outlined,
          onPressed: onLeaderboard,
        ),
        const SizedBox(width: 6),
        BrutalIconButton(
          icon: Icons.workspace_premium_outlined,
          onPressed: onAchievements,
        ),
      ],
    );
  }
}

/// One selectable emoji tile on the pick screen.
class EmojiTile extends StatelessWidget {
  final EmojiItem item;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;
  const EmojiTile({
    super.key,
    required this.item,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              selected
                  ? kCanary
                  : (unlocked ? Colors.white : const Color(0xFFE5E5E5)),
          border: Border.all(color: kBlack, width: selected ? 3 : 2),
          boxShadow:
              selected
                  ? const [BoxShadow(color: kBlack, offset: Offset(3, 3))]
                  : kShadowNone,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(
                  item.emoji,
                  style: TextStyle(fontSize: 30, color: kBlack),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                unlocked
                    ? (item.price == 0 ? item.name : item.emoji)
                    : '🔒 ${item.price}💎',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Score strip shown on the pick + game screens.
class ScoreBar extends StatelessWidget {
  final GameStore store;
  const ScoreBar({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (store.user != null)
          Expanded(
            child: Text(
              store.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        _Stat(label: 'W', value: '${store.playerWins}'),
        const SizedBox(width: 6),
        _Stat(label: 'D', value: '${store.playerDraws}'),
        const SizedBox(width: 6),
        _Stat(label: 'G', value: '${store.playerGames}'),
        if (store.winStreak > 0) ...[
          const SizedBox(width: 6),
          _Stat(label: '🔥', value: '${store.winStreak}'),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      shadow: kShadowSm,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Thin brutalist section divider.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: kBlack);
  }
}
