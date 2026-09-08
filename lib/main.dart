import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────────────────
//  Neo-Brutalist design system
// ────────────────────────────────────────────────────────────────────────────
const Color kBg = Color(0xFFFAF7F2); // warm off-white canvas
const Color kInk = Color(0xFF171717); // high-contrast dark text
const Color kBlack = Color(0xFF000000);

// Accent palette
const Color kCanary = Color(0xFFFDE047); // primary CTA
const Color kCanarySoft = Color(0xFFFEF08A);
const Color kLavender = Color(0xFFE9D5FF);
const Color kMint = Color(0xFFA7F3D0);
const Color kCoral = Color(0xFFFECDD3);
const Color kSky = Color(0xFFBAE6FD);

// Hard-edge offset shadows (no blur)
const List<BoxShadow> kShadow = [
  BoxShadow(color: kBlack, offset: Offset(4, 4)),
];
const List<BoxShadow> kShadowSm = [
  BoxShadow(color: kBlack, offset: Offset(3, 3)),
];
const List<BoxShadow> kShadowLg = [
  BoxShadow(color: kBlack, offset: Offset(6, 6)),
];
const List<BoxShadow> kShadowNone = [BoxShadow(color: Colors.transparent)];

void main() {
  runApp(const EmojiTicTacToe());
}

// ────────────────────────────────────────────────────────────────────────────
//  Emoji catalog + GameStore (diamond currency)
// ────────────────────────────────────────────────────────────────────────────
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

class GameStore extends ChangeNotifier {
  int _diamonds = kStartingDiamonds;
  final Set<String> _unlocked = {};

  GameStore() {
    for (final item in kCatalog) {
      if (item.price == 0) _unlocked.add(item.emoji);
    }
  }

  int get diamonds => _diamonds;
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
}

// ────────────────────────────────────────────────────────────────────────────
//  Reusable brutalist pieces
// ────────────────────────────────────────────────────────────────────────────
class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? shadow;
  const BrutalCard({
    super.key,
    required this.child,
    this.bg = Colors.white,
    this.padding = const EdgeInsets.all(12),
    this.shadow = kShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: kBlack, width: 2),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color bg;
  final bool enabled;
  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.bg = kCanary,
    this.enabled = true,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final usable = widget.enabled && widget.onPressed != null;
    return GestureDetector(
      onTapDown: usable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: usable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: usable ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: usable ? widget.bg : const Color(0xFFE5E5E5),
          border: Border.all(color: kBlack, width: 2),
          boxShadow: _pressed || !usable
              ? kShadowNone
              : const [BoxShadow(color: kBlack, offset: Offset(4, 4))],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: kBlack,
          ),
        ),
      ),
    );
  }
}

class DiamondBadge extends StatelessWidget {
  final GameStore store;
  const DiamondBadge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return BrutalCard(
          shadow: kShadowSm,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💎', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '${store.diamonds}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kBlack,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _gradientColor(String emoji) {
  final code = emoji.codeUnitAt(0);
  switch (code % 6) {
    case 0:
      return kLavender;
    case 1:
      return kMint;
    case 2:
      return kCoral;
    case 3:
      return kSky;
    case 4:
      return kCanarySoft;
    default:
      return const Color(0xFFE5E5E5);
  }
}

// ────────────────────────────────────────────────────────────────────────────
class EmojiTicTacToe extends StatefulWidget {
  const EmojiTicTacToe({super.key});

  @override
  State<EmojiTicTacToe> createState() => _EmojiTicTacToeState();
}

class _EmojiTicTacToeState extends State<EmojiTicTacToe> {
  final GameStore _store = GameStore();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emoji Tic-Tac-Toe',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'Gilroy',
        colorScheme: const ColorScheme.light(
          primary: kBlack,
          surface: kBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(color: kBlack, thickness: 2),
      ),
      home: OnboardingPage(store: _store),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Onboarding page
// ────────────────────────────────────────────────────────────────────────────
class OnboardingPage extends StatefulWidget {
  final GameStore store;
  const OnboardingPage({super.key, required this.store});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late Animation<double> _titleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutBack,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    );
    _startAnimations();
  }

  void _startAnimations() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _titleController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrutalCard(
                    shadow: kShadowSm,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      '🎮 EMOJI\nTIC-TAC-TOE',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: kBlack,
                      ),
                    ),
                  ),
                  DiamondBadge(store: widget.store),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _titleAnimation,
                          child: Column(
                            children: [
                              _letter('T'),
                              _letter('I'),
                              _letter('C'),
                              const SizedBox(height: 14),
                              Container(
                                height: 6,
                                width: 120,
                                color: kCanary,
                              ),
                              const SizedBox(height: 4),
                              Container(height: 4, width: 90, color: kBlack),
                              const SizedBox(height: 14),
                              _letter('T'),
                              _letter('A'),
                              _letter('C'),
                              const SizedBox(height: 14),
                              _letter('T'),
                              _letter('O'),
                              _letter('E'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        ScaleTransition(
                          scale: _buttonAnimation,
                          child: BrutalButton(
                            label: 'START GAME',
                            bg: kCoral,
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, a, s) =>
                                      EmojiSelectionPage(store: widget.store),
                                  transitionsBuilder: (context, a, s, child) =>
                                      SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1, 0),
                                          end: Offset.zero,
                                        ).animate(a),
                                        child: child,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letter(String ch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBlack, width: 3),
        boxShadow: kShadow,
      ),
      child: Text(
        ch,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 72,
          height: 1,
          fontWeight: FontWeight.w900,
          color: kInk,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Emoji selection page
// ────────────────────────────────────────────────────────────────────────────
class EmojiSelectionPage extends StatefulWidget {
  final GameStore store;
  const EmojiSelectionPage({super.key, required this.store});

  @override
  State<EmojiSelectionPage> createState() => _EmojiSelectionPageState();
}

class _EmojiSelectionPageState extends State<EmojiSelectionPage> {
  String? player1Emoji;
  String? player2Emoji;

  List<EmojiItem> get _catalog => kCatalog;

  void _startGame() {
    if (player1Emoji != null &&
        player2Emoji != null &&
        player1Emoji != player2Emoji) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => TicTacToePage(
                store: widget.store,
                player1Emoji: player1Emoji!,
                player2Emoji: player2Emoji!,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pick two DIFFERENT emojis!'),
          backgroundColor: kBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: kBlack, width: 2),
          ),
        ),
      );
    }
  }

  void _onEmojiTap(String emoji) {
    final price = widget.store.priceOf(emoji);
    if (widget.store.isUnlocked(emoji) || price == 0) {
      return; // handled as selection
    }
    _promptBuy(context, emoji);
  }

  void _promptBuy(BuildContext context, String emoji) {
    final price = widget.store.priceOf(emoji);
    final affordable = widget.store.diamonds >= price;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: kBlack, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: kCanary,
              child: const Text(
                '🔒 LOCKED EMOJI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: kBlack,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Win games to earn 💎 diamonds,\nthen use them to unlock new emojis!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: kInk),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 10),
                Text(
                  '💎 $price',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: kBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AffordButton(
                affordable: affordable,
                label: affordable ? 'BUY FOR 💎 $price' : 'NOT ENOUGH 💎',
                onPressed: affordable
                    ? () {
                        Navigator.pop(context);
                        if (widget.store.buy(emoji)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$emoji unlocked! 🎉'),
                              backgroundColor: kBlack,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                                side: const BorderSide(
                                  color: kBlack,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker({
    required String title,
    required int playerNum,
    required String? selectedEmoji,
    required ValueChanged<String> onSelected,
  }) {
    final accent = playerNum == 1 ? kSky : kMint;
    return BrutalCard(
      bg: const Color(0xFFE8E8E8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: accent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: kBlack,
                  ),
                ),
                if (selectedEmoji != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: kBlack, width: 2),
                    ),
                    child: Text(
                      selectedEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _catalog.length,
            itemBuilder: (context, index) {
              final item = _catalog[index];
              final emoji = item.emoji;
              final isUnlocked =
                  widget.store.isUnlocked(emoji) || item.price == 0;
              final isSelected = selectedEmoji == emoji;
              final isUsedByOther =
                  (player1Emoji == emoji || player2Emoji == emoji) &&
                  !isSelected;

              return ListenableBuilder(
                listenable: widget.store,
                builder: (context, _) => _EmojiCell(
                  item: item,
                  unlocked: isUnlocked,
                  selected: isSelected,
                  disabled: !isUnlocked || isUsedByOther,
                  onTap: () {
                    if (!isUnlocked) {
                      _onEmojiTap(emoji);
                    } else if (!isUsedByOther) {
                      onSelected(emoji);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButton(onPressed: () => Navigator.pop(context)),
                      const Expanded(
                        child: Text(
                          'CHOOSE YOUR EMOJIS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: kBlack,
                          ),
                        ),
                      ),
                      DiamondBadge(store: widget.store),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '💎 WIN TO EARN • TAP 🔒 TO BUY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: kInk,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildEmojiPicker(
                      title: 'PLAYER 1',
                      playerNum: 1,
                      selectedEmoji: player1Emoji,
                      onSelected: (e) => setState(() => player1Emoji = e),
                    ),
                    const SizedBox(height: 20),
                    _buildEmojiPicker(
                      title: 'PLAYER 2',
                      playerNum: 2,
                      selectedEmoji: player2Emoji,
                      onSelected: (e) => setState(() => player2Emoji = e),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BrutalButton(
                          label: '🛒 STORE',
                          bg: kSky,
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, a, s) =>
                                    StorePage(store: widget.store),
                                transitionsBuilder:
                                    (context, a, s, child) => SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(a),
                                      child: child,
                                    ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        BrutalButton(
                          label: 'START GAME',
                          bg: kCanary,
                          enabled:
                              player1Emoji != null &&
                              player2Emoji != null &&
                              player1Emoji != player2Emoji,
                          onPressed: _startGame,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCell extends StatefulWidget {
  final EmojiItem item;
  final bool unlocked;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  const _EmojiCell({
    required this.item,
    required this.unlocked,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_EmojiCell> createState() => _EmojiCellState();
}

class _EmojiCellState extends State<_EmojiCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final usable = !widget.disabled;
    final bg = widget.selected ? kLavender : Colors.white;
    return GestureDetector(
      onTapDown: usable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: usable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: usable ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.unlocked
              ? (widget.disabled
                    ? const Color(0xFFDDDDDD)
                    : bg)
              : const Color(0xFFE8E8E8),
          border: Border.all(
            color: kBlack,
            width: widget.selected ? 3 : 2,
          ),
          boxShadow: (_pressed || widget.disabled) ? kShadowNone : kShadowSm,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Opacity(
                opacity: widget.disabled ? 0.4 : 1,
                child: Text(
                  widget.item.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            if (!widget.unlocked)
              Positioned(
                bottom: 2,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  color: kBlack,
                  child: Text(
                    '💎${widget.item.price}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!widget.unlocked)
              const Center(
                child: Text('🔒', style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Store page (buy emojis)
// ────────────────────────────────────────────────────────────────────────────
class StorePage extends StatelessWidget {
  final GameStore store;
  const StorePage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _BackButton(onPressed: () => Navigator.pop(context)),
                  const Expanded(
                    child: Text(
                      'EMOJI STORE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: kBlack,
                      ),
                    ),
                  ),
                  DiamondBadge(store: store),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '💎 WIN GAMES TO EARN • SPEND TO UNLOCK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: kInk,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: kCatalog.length,
                itemBuilder: (context, index) {
                  final item = kCatalog[index];
                  return _StoreItemCard(store: store, item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  final GameStore store;
  final EmojiItem item;
  const _StoreItemCard({required this.store, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final owned = store.isUnlocked(item.emoji) || item.price == 0;
        final affordable = store.diamonds >= item.price;
        final bg = owned ? kMint : (affordable ? kCanarySoft : kCoral);

        return BrutalCard(
          bg: bg,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              Text(
                item.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: kBlack,
                ),
              ),
              if (owned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: kBlack,
                  child: const Text(
                    'OWNED ✓',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: Colors.white,
                  child: Text(
                    '💎 ${item.price}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kBlack,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BrutalButton(
                  label: owned ? 'OWNED' : (affordable ? 'BUY' : 'NO 💎'),
                  bg: owned ? kMint : kCanary,
                  enabled: !owned && affordable,
                  onPressed: () {
                    if (store.buy(item.emoji)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.emoji} unlocked! 🎉'),
                          backgroundColor: kBlack,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(color: kBlack, width: 2),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Tic-Tac-Toe game page
// ────────────────────────────────────────────────────────────────────────────
class TicTacToePage extends StatefulWidget {
  final GameStore store;
  final String player1Emoji;
  final String player2Emoji;

  const TicTacToePage({
    super.key,
    required this.store,
    required this.player1Emoji,
    required this.player2Emoji,
  });

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage>
    with TickerProviderStateMixin {
  late List<String> board;
  late String currentPlayer;
  String winner = '';
  bool isDraw = false;
  Map<String, int> scores = {'player1': 0, 'player2': 0, 'draws': 0};

  late AnimationController _boardController;
  late AnimationController _winnerController;
  late Animation<double> _boardAnimation;
  late Animation<double> _winnerAnimation;

  @override
  void initState() {
    super.initState();
    board = List.filled(9, '');
    currentPlayer = widget.player1Emoji;

    _boardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _winnerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _boardAnimation = CurvedAnimation(
      parent: _boardController,
      curve: Curves.easeOutBack,
    );
    _winnerAnimation = CurvedAnimation(
      parent: _winnerController,
      curve: Curves.easeOut,
    );
    _boardController.forward();
  }

  @override
  void dispose() {
    _boardController.dispose();
    _winnerController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (board[index] == '' && winner == '' && !isDraw) {
      setState(() {
        board[index] = currentPlayer;
        if (_checkWinner(currentPlayer)) {
          winner = currentPlayer;
          final key =
              currentPlayer == widget.player1Emoji ? 'player1' : 'player2';
          scores[key] = scores[key]! + 1;
          widget.store.addDiamonds(kWinReward);
          _winnerController.forward();
        } else if (!board.contains('')) {
          isDraw = true;
          scores['draws'] = scores['draws']! + 1;
          _winnerController.forward();
        } else {
          currentPlayer =
              currentPlayer == widget.player1Emoji
                  ? widget.player2Emoji
                  : widget.player1Emoji;
        }
      });
    }
  }

  bool _checkWinner(String player) {
    List<List<int>> winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    return winPatterns.any(
      (pattern) => pattern.every((index) => board[index] == player),
    );
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = widget.player1Emoji;
      winner = '';
      isDraw = false;
    });
    _winnerController.reset();
    _boardController.reset();
    _boardController.forward();
  }

  void _resetScores() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: kBlack, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: kCoral,
              child: const Text(
                'RESET SCORES?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: kBlack,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Are you sure you want to reset all scores?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: kInk),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      label: 'CANCEL',
                      bg: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrutalButton(
                      label: 'RESET',
                      bg: kCoral,
                      onPressed: () {
                        setState(() {
                          scores = {'player1': 0, 'player2': 0, 'draws': 0};
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player1Color = _gradientColor(widget.player1Emoji);
    final player2Color = _gradientColor(widget.player2Emoji);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BackButton(onPressed: () => Navigator.pop(context)),
                  const Text(
                    'EMOJI TIC-TAC-TOE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: kBlack,
                    ),
                  ),
                  _IconButton(icon: Icons.replay, onPressed: _resetScores),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ScoreCard(
                    emoji: widget.player1Emoji,
                    color: player1Color,
                    score: scores['player1']!,
                    label: 'P1',
                  ),
                  _ScoreCard(
                    emoji: '🤝',
                    color: kCanarySoft,
                    score: scores['draws']!,
                    label: 'DRAW',
                  ),
                  _ScoreCard(
                    emoji: widget.player2Emoji,
                    color: player2Color,
                    score: scores['player2']!,
                    label: 'P2',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            DiamondBadge(store: widget.store),
            const SizedBox(height: 10),
            if (winner == '' && !isDraw)
              BrutalCard(
                shadow: kShadowSm,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: kLavender,
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      currentPlayer,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ],
                ),
              ),
            if (winner != '' || isDraw)
              ScaleTransition(
                scale: _winnerAnimation,
                child: BrutalCard(
                  bg: kCanarySoft,
                  shadow: kShadowSm,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDraw
                            ? "IT'S A DRAW! 🤝"
                            : '$winner WINS! 🎉',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kBlack,
                        ),
                      ),
                      if (!isDraw) ...[
                        const SizedBox(height: 6),
                        const Text(
                          '+💎 REWARD EARNED',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: kBlack,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ScaleTransition(
                  scale: _boardAnimation,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 9,
                    itemBuilder: (context, index) => _buildGameCell(index),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: BrutalButton(
                label: 'NEW ROUND',
                bg: kCanary,
                onPressed: _resetGame,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCell(int index) {
    final filled = board[index] != '';
    final isP1 = board[index] == widget.player1Emoji;
    final cellColor = !filled
        ? Colors.white
        : isP1
        ? kSky
        : kCoral;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(color: kBlack, width: 3),
        boxShadow: kShadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(index),
          child: Center(
            child: AnimatedScale(
              scale: filled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Text(
                board[index],
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
//  Shared brutalist chrome
// ────────────────────────────────────────────────────────────────────────────
class AffordButton extends StatelessWidget {
  final bool affordable;
  final String label;
  final VoidCallback? onPressed;
  const AffordButton({
    super.key,
    required this.affordable,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalButton(
      label: label,
      bg: affordable ? kCanary : kCoral,
      enabled: affordable && onPressed != null,
      onPressed: affordable ? onPressed : null,
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final int score;
  final String label;
  const _ScoreCard({
    required this.emoji,
    required this.color,
    required this.score,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: kBlack, width: 2),
        boxShadow: kShadowSm,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: kBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _IconButton(icon: Icons.arrow_back, onPressed: onPressed);
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _IconButton({required this.icon, required this.onPressed});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.all(10),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kBlack, width: 2),
          boxShadow: _pressed ? kShadowNone : kShadowSm,
        ),
        child: Icon(widget.icon, color: kBlack, size: 24),
      ),
    );
  }
}
