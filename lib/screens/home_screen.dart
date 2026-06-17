// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = Preferences.instance.getCompletedCount();
    final totalStars = Preferences.instance.getTotalStars();

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        CustomPaint(
            size: MediaQuery.of(context).size, painter: _BlueprintBgPainter()),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),
            // piece snapping into outline
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_ctrl.value);
                return SizedBox(
                  width: 170,
                  height: 100,
                  child: Stack(children: [
                    // dashed target outline (L tromino)
                    Positioned(
                      left: 96,
                      top: 16,
                      child: CustomPaint(
                        size: const Size(66, 66),
                        painter: _OutlinePainter(),
                      ),
                    ),
                    // moving piece
                    Positioned(
                      left: 8 + t * 88,
                      top: 16 + t * 0,
                      child: Opacity(
                        opacity: 0.55 + 0.45 * t,
                        child: CustomPaint(
                          size: const Size(66, 66),
                          painter: _LPiecePainter(),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
            const SizedBox(height: 18),
            Text('SNAPFIT',
                style: techno(44,
                    color: kAccent, weight: FontWeight.w900, letterSpacing: 9)),
            const SizedBox(height: 8),
            Text('EVERY PIECE HAS ITS PLACE',
                style: techno(12, color: kTextDim, letterSpacing: 4)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _chip(Icons.check_circle_outline, '$completed / $kTotalLevels',
                  kEasyColor),
              const SizedBox(width: 14),
              _chip(Icons.star, '$totalStars', kStarOn),
            ]),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(children: [
                _btn('PLAY', Icons.play_arrow_rounded, true, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen()));
                }),
                const SizedBox(height: 14),
                _btn('SETTINGS', Icons.tune_rounded, false, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                }),
              ]),
            ),
            const SizedBox(height: 56),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: techno(13)),
        ]),
      );

  Widget _btn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF2779C9), Color(0xFF4FA3E8)])
                : null,
            color: primary ? null : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.7) : kBorder,
                width: primary ? 1.5 : 1),
            boxShadow: primary
                ? [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 22)]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? Colors.white : kTextDim, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: techno(15,
                    color: primary ? Colors.white : kTextDim,
                    letterSpacing: 3)),
          ]),
        ),
      );
}

class _BlueprintBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = kGridLine.withOpacity(0.6)
      ..strokeWidth = 0.7;
    final bold = Paint()
      ..color = kGridLine
      ..strokeWidth = 1.4;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          x % 120 == 0 ? bold : fine);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          y % 120 == 0 ? bold : fine);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LPiecePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = const Color(0xFFFFA726);
    final cell = size.width / 2;
    for (final p in const [Offset(0, 0), Offset(0, 1), Offset(1, 1)]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  p.dx * cell + 2, p.dy * cell + 2, cell - 4, cell - 4),
              const Radius.circular(5)),
          Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _OutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kBlueprint.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cell = size.width / 2;
    for (final o in const [Offset(0, 0), Offset(0, 1), Offset(1, 1)]) {
      final rect = Rect.fromLTWH(
          o.dx * cell + 2, o.dy * cell + 2, cell - 4, cell - 4);
      // dashed rect
      const dash = 6.0;
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)));
      final metrics = path.computeMetrics();
      for (final m in metrics) {
        double t = 0;
        while (t < m.length) {
          canvas.drawPath(m.extractPath(t, t + dash), p);
          t += dash * 2;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
