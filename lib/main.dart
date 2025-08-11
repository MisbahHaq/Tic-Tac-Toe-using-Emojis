import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';


void main() {
  runApp(MatchCardsApp());
}

class MatchCardsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: MatchCardsHome(),
    );
  }
}

class MatchCardsHome extends StatefulWidget {
  @override
  _MatchCardsHomeState createState() => _MatchCardsHomeState();
}

class _MatchCardsHomeState extends State<MatchCardsHome>
    with SingleTickerProviderStateMixin {
  // Colors inspired by the image
  static const Color backgroundBlack = Color(0xFF060606);
  static const Color cardYellow = Color(0xFFFFE400); // bright yellow
  static const Color cardPurple = Color(0xFFDCCAFF); // soft purple back
  static const Color phoneBlack = Color(0xFF0F0F0F);
  static const Color subtleGray = Color(0xFF9E9E9E);

  // available emojis (expandable)
  final List<String> emojiPool = [
    '👽',
    '🤖',
    '🤡',
    '🎃',
    '😈',
    '👻',
    '🔥',
    '❤️',
    '✨',
    '🌟',
    '🍒',
    '🍉',
    '🐶',
    '🐱',
    '🦊',
    '🐼',
    '🦄',
    '🍕',
    '🍔',
    '⚽',
    '🏀',
    '🎧',
    '🎮',
    '🌈',
  ];

  int rows = 4;
  int cols = 4;

  late List<_CardModel> cards;
  _CardModel? firstFlipped;
  _CardModel? secondFlipped;
  bool waiting = false;

  // Timer
  Stopwatch stopwatch = Stopwatch();
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void _startTimer() {
    ticker?.cancel();
    stopwatch.reset();
    stopwatch.start();
    ticker = Timer.periodic(Duration(milliseconds: 30), (_) {
      setState(() {});
    });
  }

  void _stopTimer() {
    stopwatch.stop();
    ticker?.cancel();
  }

  String _formattedTime() {
    final ms = stopwatch.elapsedMilliseconds;
    final centi = ((ms % 1000) / 10).floor().toString().padLeft(2, '0');
    final totalSeconds = (ms / 1000).floor();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds.$centi";
  }

  void _newGame({int? newRows, int? newCols}) {
    if (newRows != null) rows = newRows;
    if (newCols != null) cols = newCols;
    final count = rows * cols;
    // ensure even count
    final evenCount = (count % 2 == 0) ? count : count - 1;
    final pairs = evenCount ~/ 2;

    // select emojis
    final rnd = Random();
    final _pool = List<String>.from(emojiPool);
    _pool.shuffle(rnd);
    if (pairs > _pool.length) {
      // duplicate pool if not enough emojis (unlikely)
      while (pairs > _pool.length) {
        _pool.addAll(List<String>.from(emojiPool));
      }
      _pool.shuffle(rnd);
    }

    final selected = _pool.sublist(0, pairs);
    final List<String> tileEmojis = [];
    for (var e in selected) {
      tileEmojis.add(e);
      tileEmojis.add(e);
    }
    tileEmojis.shuffle(rnd);

    cards = List.generate(evenCount, (i) {
      return _CardModel(id: i, emoji: tileEmojis[i]);
    });

    // If grid had an odd cell and was reduced, add an "invisible" disabled card so layout stays in grid.
    if (count != evenCount) {
      cards.add(_CardModel(id: evenCount, emoji: '', disabled: true));
    }

    firstFlipped = null;
    secondFlipped = null;
    waiting = false;
    _startTimer();
    setState(() {});
  }

  void _onCardTap(_CardModel card) {
    if (waiting) return;
    if (card.isMatched || card.isFaceUp || card.disabled) return;

    setState(() => card.isFaceUp = true);

    if (firstFlipped == null) {
      firstFlipped = card;
      return;
    }

    secondFlipped = card;
    waiting = true;

    Future.delayed(Duration(milliseconds: 600), () {
      if (firstFlipped!.emoji == secondFlipped!.emoji) {
        setState(() {
          firstFlipped!.isMatched = true;
          secondFlipped!.isMatched = true;
        });
      } else {
        setState(() {
          firstFlipped!.isFaceUp = false;
          secondFlipped!.isFaceUp = false;
        });
      }

      firstFlipped = null;
      secondFlipped = null;
      waiting = false;

      // check win
      if (cards.where((c) => !c.disabled).every((c) => c.isMatched)) {
        _stopTimer();
        _showWinDialog();
      }
    });
  }

  void _showWinDialog() async {
    // show in-app full-screen card similar to the design
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final time = _formattedTime();
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: cardYellow,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔥', style: TextStyle(fontSize: 42)),
                SizedBox(height: 10),
                Text(
                  'You are on\nfire!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: cardYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: Text('New Game', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _newGame();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // small "MATCH CARDS" logo top-left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MATCH',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'CARDS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Spacer(),
          // timer column (two lines like image)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stopwatch.isRunning ? _formattedElapsedShort() : '00:00.00',
                style: TextStyle(
                  color: cardYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formattedTime(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          // icons (music & speaker) - purely decorative
          Row(
            children: [
              _iconBox(Icons.music_note),
              SizedBox(width: 8),
              _iconBox(Icons.volume_up),
            ],
          ),
        ],
      ),
    );
  }

  String _formattedElapsedShort() {
    final ms = stopwatch.elapsedMilliseconds;
    final seconds = (ms / 1000).toStringAsFixed(2);
    return seconds;
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: phoneBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phone-like container with a yellow rounded background area (to mimic screenshot)
    final gridCount = rows * cols;
    final actualCount = cards.length;

    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              children: [
                // Big vertical title mock (top-left phone in image)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left narrow device portrait with rotated title
                    Transform.rotate(
                      angle: -pi / 2,
                      child: Container(
                        width: 180,
                        height: 420,
                        decoration: BoxDecoration(
                          color: phoneBlack,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text(
                            'MATCH\nCARDS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 54,
                              height: 0.9,
                              color: Color(0xFFDCC7FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    // Main mock phone (game area)
                    Expanded(
                      child: Column(
                        children: [
                          // Phone device frame
                          Container(
                            constraints: BoxConstraints(
                              minHeight: 420,
                              maxWidth: 420,
                            ),
                            decoration: BoxDecoration(
                              color: phoneBlack,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 12,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildTopBar(),
                                SizedBox(height: 12),
                                // Grid area card with padding and rounded corners
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18.0,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 9 / 16,
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      child: _buildGrid(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                // bottom new game button small
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22.0,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _newGame(),
                                          child: Container(
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: cardYellow,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.black12,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'New Game',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // grid size dropdown
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: phoneBlack,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            dropdownColor: phoneBlack,
                                            value: '${rows}x${cols}',
                                            iconEnabledColor: Colors.white70,
                                            items:
                                                [
                                                  '2x2',
                                                  '2x4',
                                                  '3x4',
                                                  '4x4',
                                                  '4x6',
                                                  '6x6',
                                                ].map((e) {
                                                  return DropdownMenuItem(
                                                    value: e,
                                                    child: Text(
                                                      e,
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (val) {
                                              if (val == null) return;
                                              final parts = val.split('x');
                                              final r = int.parse(parts[0]);
                                              final c = int.parse(parts[1]);
                                              _newGame(newRows: r, newCols: c);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          // Another phone mock below (optional small preview)
                          Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: cardYellow,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Developed by Tinloof',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                // small hint / legend
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Tap tiles to reveal emoji — match pairs to win. ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextSpan(
                        text: 'Grid: ${rows}x${cols}',
                        style: TextStyle(
                          color: cardYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    // find number of visible cells
    final visibleCount = cards.length;
    // compute crossAxisCount as cols
    final cross = cols;

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: visibleCount,
      itemBuilder: (context, index) {
        final card = cards[index];
        if (card.disabled) {
          return SizedBox.shrink();
        }
        return _MemoryCard(
          model: card,
          onTap: () => _onCardTap(card),
          yellow: cardYellow,
          purple: cardPurple,
        );
      },
    );
  }
}

class _CardModel {
  final int id;
  final String emoji;
  bool isFaceUp;
  bool isMatched;
  bool disabled;

  _CardModel({
    required this.id,
    required this.emoji,
    this.isFaceUp = false,
    this.isMatched = false,
    this.disabled = false,
  });
}

class _MemoryCard extends StatefulWidget {
  final _CardModel model;
  final VoidCallback onTap;
  final Color yellow;
  final Color purple;

  const _MemoryCard({
    Key? key,
    required this.model,
    required this.onTap,
    required this.yellow,
    required this.purple,
  }) : super(key: key);

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 360),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // sync animation with model
    if (widget.model.isFaceUp && !_controller.isCompleted) {
      _controller.forward();
    } else if (!widget.model.isFaceUp && _controller.isCompleted) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: widget.yellow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(widget.model.emoji, style: TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: widget.purple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text('', style: TextStyle(fontSize: 18))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If matched, show slightly faded yellow but keep it visible
    return GestureDetector(
      onTap:
          widget.model.disabled || widget.model.isMatched ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, child) {
          final anim = _flipAnim.value;
          final isFront = anim > 0.5;
          final angle = anim * pi;
          return Transform(
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child:
                  isFront
                      ? Transform(
                        transform: Matrix4.rotationY(pi),
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: widget.model.isMatched ? 0.85 : 1,
                          child: _buildFront(),
                        ),
                      )
                      : _buildBack(),
            ),
          );
        },
      ),
    );
  }
}
