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

Color gradientColor(String emoji) {
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
  final EdgeInsetsGeometry padding;
  final double fontSize;
  const BrutalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.bg = kCanary,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
    this.fontSize = 18,
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
        padding: widget.padding,
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
            fontSize: widget.fontSize,
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
  final int diamonds;
  const DiamondBadge({super.key, required this.diamonds});

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      shadow: kShadowSm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💎', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$diamonds',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrutalIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const BrutalIconButton({super.key, required this.icon, required this.onPressed});

  @override
  State<BrutalIconButton> createState() => _BrutalIconButtonState();
}

class _BrutalIconButtonState extends State<BrutalIconButton> {
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
      fontSize: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }
}

void pushBrutal(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, a, s) => page,
      transitionsBuilder: (context, a, s, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(a),
        child: child,
      ),
    ),
  );
}