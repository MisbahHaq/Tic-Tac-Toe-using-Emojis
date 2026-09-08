import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';
import 'services.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmojiTicTacToe());
}

class EmojiTicTacToe extends StatefulWidget {
  const EmojiTicTacToe({super.key});

  @override
  State<EmojiTicTacToe> createState() => _EmojiTicTacToeState();
}

class _EmojiTicTacToeState extends State<EmojiTicTacToe> {
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
      title: 'Emoji Tic-Tac-Toe',
      debugShowCheckedModeBanner: false,
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
  GameMode _mode = GameMode.twoPlayer;

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
                  child: _HomeContent(
                    store: widget.store,
                    mode: _mode,
                    onModeChanged: (m) => setState(() => _mode = m),
                  ),
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
  final GameMode mode;
  final ValueChanged<GameMode> onModeChanged;
  const _HomeContent({
    required this.store,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeaderRow(
          store: store,
          onStore: () => pushBrutal(context, StorePage(store: store)),
          onLeaderboard: () =>
              pushBrutal(context, LeaderboardPage(store: store)),
        ),
        const SizedBox(height: 32),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'EMOJI\nTIC·TAC·TOE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 64,
              height: 0.95,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: kBlack,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            '🐶  VS  🐼',
            style: TextStyle(fontSize: 44),
          ),
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
            active: mode == m,
            onTap: () => onModeChanged(m),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        BrutalButton(
          label: 'PLAY ▶',
          bg: kCanary,
          onPressed: () =>
              pushBrutal(context, EmojiSelectionPage(store: store, mode: mode)),
        ),
        const SizedBox(height: 16),
        _SignInChip(store: store),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.active, required this.onTap});

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
          boxShadow: active
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: kBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInChip extends StatelessWidget {
  final GameStore store;
  const _SignInChip({required this.store});

  @override
  Widget build(BuildContext context) {
    final ready = store.firebaseReady;
    final user = store.user;
    return BrutalCard(
      bg: ready ? kSky : const Color(0xFFE5E5E5),
      shadow: kShadowSm,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GestureDetector(
        onTap: ready ? () => pushBrutal(context, SignInPage(store: store)) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user != null ? '⭕' : '👤', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                user != null
                    ? 'SIGNED IN: ${user.name.toUpperCase()}'
                    : (ready ? 'SIGN IN FOR LEADERBOARD' : 'SIGN-IN: FIREBASE NOT SET UP'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
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

// ────────────────────────────────────────────────────────────────────────────
//  Emoji selection
// ────────────────────────────────────────────────────────────────────────────
class EmojiSelectionPage extends StatelessWidget {
  final GameStore store;
  final GameMode mode;
  const EmojiSelectionPage({super.key, required this.store, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _EmojiSelectionBody(store: store, mode: mode),
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
  const _EmojiSelectionBody({required this.store, required this.mode});

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
                onRandom: () =>
                    setState(() => _p1 = _randomFree(widget.store)),
              ),
            ),
            const SizedBox(height: 8),
            _EmojiGrid(
              store: widget.store,
              selected: _p1,
              onPick: (e) => setState(() => _p1 = e),
            ),
            const SizedBox(height: 14),
            BrutalCard(
              bg: vsAi ? kMint : _p2Color,
              shadow: vsAi ? kShadowNone : kShadow,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: vsAi
                  ? const _PickerHeader(
                      label: 'CPU OPPONENT',
                      selected: kAiEmoji,
                      hint: '🤖 NO STOCK',
                    )
                  : _PickerHeader(
                      label: 'PLAYER 2',
                      selected: _p2,
                      onRandom: () =>
                          setState(() => _p2 = _randomFree(widget.store)),
                    ),
            ),
            if (!vsAi) ...[
              const SizedBox(height: 8),
              _EmojiGrid(
                store: widget.store,
                selected: _p2,
                onPick: (e) => setState(() => _p2 = e),
              ),
            ],
            const SizedBox(height: 18),
            BrutalButton(
              label: widget.mode.label,
              onPressed: () => pushBrutal(
                context,
                GamePage(
                  store: widget.store,
                  mode: widget.mode,
                  p1Emoji: _p1,
                  p2Emoji: widget.mode.isAi ? kAiEmoji : _p2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _randomFree(GameStore store) {
    final free = kCatalog.where((i) => store.isUnlocked(i.emoji)).toList();
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
                        horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: kBlack, width: 2),
                    ),
                    child: const Text(
                      '🎲',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final GameStore store;
  final String selected;
  final ValueChanged<String> onPick;
  const _EmojiGrid({
    required this.store,
    required this.selected,
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
  const GamePage({
    super.key,
    required this.store,
    required this.mode,
    required this.p1Emoji,
    required this.p2Emoji,
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

  bool get _isAiTurn =>
      widget.mode.isAi && _current == widget.p2Emoji;

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _board = List.filled(9, null);
      _current = widget.p1Emoji;
      _over = false;
      _reported = false;
      _winningLine = null;
    });
  }

  Future<void> _onCell(int i) async {
    if (_over || _board[i] != null || _isAiTurn) return;
    _move(i, _current);
  }

  void _move(int i, String mark) {
    setState(() {
      _board[i] = mark;
      _current = mark == widget.p1Emoji ? widget.p2Emoji : widget.p1Emoji;
    });
    _checkEnd();
    if (!_over && _isAiTurn) {
      _aiTimer?.cancel();
      _aiTimer = Timer(const Duration(milliseconds: 420), _aiMove);
    }
  }

  void _aiMove() {
    if (!mounted || _over) return;
    final empties = [
      for (int i = 0; i < 9; i++)
        if (_board[i] == null) i
    ];
    if (empties.isEmpty) return;
    final pick = widget.mode == GameMode.vsAiEasy
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
      final line = _winLines.firstWhere((l) =>
          _board[l[0]] != null &&
          _board[l[0]] == _board[l[1]] &&
          _board[l[0]] == _board[l[2]]);
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
    widget.store.reportRound(p1Win: p1Won, p2Win: p2Won);
    final playerWon = widget.mode.isAi ? p1Won : p1Won || p2Won;
    if (playerWon) widget.store.addDiamonds(kWinReward);
    _showResult(p1Won: p1Won, p2Won: p2Won);
  }

  void _showResult({required bool p1Won, required bool p2Won}) {
    final isDraw = !p1Won && !p2Won;
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
      builder: (context) => Dialog(
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
              if (p1Won) ...[
                const Text(
                  '+💎 REWARD',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrutalButton(
                      label: 'PLAY AGAIN',
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
                          horizontal: 20, vertical: 14),
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
                    ),
                    const SizedBox(height: 16),
                    _Board(
                      board: _board,
                      winningLine: _winningLine,
                      onTap: _onCell,
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
  const _TurnStrip({
    required this.p1,
    required this.p2,
    required this.current,
    required this.isAiMode,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == p1;
    final label = isAiMode && active ? 'YOUR TURN' : '${active ? 'P1' : 'P2'} TURN';
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
                label,
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

class _Board extends StatelessWidget {
  final List<String?> board;
  final List<int>? winningLine;
  final ValueChanged<int> onTap;
  const _Board({
    required this.board,
    required this.winningLine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
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
          final mark = board[i];
          final isWin = winningLine?.contains(i) ?? false;
          return GestureDetector(
            key: ValueKey('cell-$i'),
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: isWin
                    ? kCanary
                    : (mark == null ? Colors.white : gradientColor(mark)),
                border: Border.all(color: kBlack, width: 2),
                boxShadow: const [
                  BoxShadow(color: kBlack, offset: Offset(4, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  mark ?? '',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          );
        },
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
                          'NEW FIGHTERS.',
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
                        if (!context.mounted) return;
                        setState(() => _busy = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: ok ? kMint : kCoral,
                            content: Text(
                              ok ? 'WELCOME!' : 'SIGN-IN FAILED / CANCELLED',
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

  @override
  void initState() {
    super.initState();
    _future = widget.store.services.fetchLeaderboard();
  }

  void _refresh() {
    setState(() {
      _future = widget.store.services.fetchLeaderboard();
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
                        'GLOBAL TOP WINS · UPDATED AFTER EACH MATCH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
                              isMe: widget.store.user != null &&
                                  entries[i].name == widget.store.user!.name,
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
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
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