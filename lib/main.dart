import 'package:flutter/material.dart';

void main() {
  runApp(const EmojiTicTacToe());
}

class EmojiTicTacToe extends StatelessWidget {
  const EmojiTicTacToe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const EmojiSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmojiSelectionPage extends StatefulWidget {
  const EmojiSelectionPage({super.key});

  @override
  State<EmojiSelectionPage> createState() => _EmojiSelectionPageState();
}

class _EmojiSelectionPageState extends State<EmojiSelectionPage> {
  String? player1Emoji;
  String? player2Emoji;

  final List<String> emojiList = [
    '😸',
    '🐶',
    '🐼',
    '🐵',
    '🦊',
    '🐻',
    '🐨',
    '🐯',
    '🐷',
    '🐸',
    '🦁',
    '🐮',
  ];

  void _startGame() {
    if (player1Emoji != null &&
        player2Emoji != null &&
        player1Emoji != player2Emoji) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => TicTacToePage(
                player1Emoji: player1Emoji!,
                player2Emoji: player2Emoji!,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Choose different emojis for both players"),
        ),
      );
    }
  }

  Widget _emojiPicker(String? selectedEmoji, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          emojiList.map((emoji) {
            return GestureDetector(
              onTap: () => onSelected(emoji),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      selectedEmoji == emoji ? Colors.blue[100] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        selectedEmoji == emoji
                            ? Colors.blue
                            : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Select Emojis"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Player 1 Choose Your Emoji",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _emojiPicker(
              player1Emoji,
              (emoji) => setState(() => player1Emoji = emoji),
            ),
            const SizedBox(height: 20),
            const Text(
              "Player 2 Choose Your Emoji",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _emojiPicker(
              player2Emoji,
              (emoji) => setState(() => player2Emoji = emoji),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Start Game", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class TicTacToePage extends StatefulWidget {
  final String player1Emoji;
  final String player2Emoji;

  const TicTacToePage({
    super.key,
    required this.player1Emoji,
    required this.player2Emoji,
  });

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  late List<String> board;
  late String currentPlayer;
  String winner = '';

  @override
  void initState() {
    super.initState();
    board = List.filled(9, '');
    currentPlayer = widget.player1Emoji;
  }

  void _handleTap(int index) {
    if (board[index] == '' && winner == '') {
      setState(() {
        board[index] = currentPlayer;
        if (_checkWinner(currentPlayer)) {
          winner = currentPlayer;
        } else if (!board.contains('')) {
          winner = 'Draw';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Emoji Tic-Tac-Toe"), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (winner != '')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                winner == 'Draw' ? "It's a Draw! 🤝" : "$winner Wins! 🎉",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _handleTap(index),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      board[index],
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Reset Game", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
