// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../game/painters.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _victoryCtrl;
  late final Animation<double> _victoryAnim;

  @override
  void initState() {
    super.initState();
    _victoryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _victoryAnim =
        CurvedAnimation(parent: _victoryCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().loadLevel(widget.levelIndex);
    });
  }

  @override
  void dispose() {
    _victoryCtrl.dispose();
    super.dispose();
  }

  void _haptic() {
    if (Preferences.instance.isVibrationEnabled()) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Consumer<GameState>(builder: (ctx, st, _) {
        if (!st.initialized) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        if (st.isComplete && !_victoryCtrl.isCompleted) {
          _victoryCtrl.forward();
          if (Preferences.instance.isVibrationEnabled()) {
            HapticFeedback.heavyImpact();
          }
        }
        return Stack(children: [
          SafeArea(
            child: Column(children: [
              _hud(st),
              const SizedBox(height: 4),
              Text(
                st.selectedPiece == null
                    ? 'PICK A PIECE FROM THE TRAY'
                    : 'TAP THE BLUEPRINT TO PLACE IT',
                style: techno(10,
                    color:
                        st.selectedPiece == null ? kTextDim : kBlueprint,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              _board(st),
              const SizedBox(height: 10),
              Expanded(child: _tray(st)),
              _bottomBar(st),
              const SizedBox(height: 10),
            ]),
          ),
          if (st.isComplete) _victory(st),
        ]);
      }),
    );
  }

  Widget _hud(GameState st) {
    final diffColor = st.level.difficulty == 'Easy'
        ? kEasyColor
        : st.level.difficulty == 'Medium'
            ? kMediumColor
            : kHardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kTextDim, size: 16),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text('LEVEL ${st.level.index + 1}',
              style: techno(14, letterSpacing: 3)),
          Text(st.level.difficulty.toUpperCase(),
              style: techno(10, color: diffColor, letterSpacing: 2)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${st.placed.length} / ${st.level.pieces.length}',
              style: techno(16, color: kAccent, weight: FontWeight.w900)),
          Text('PIECES', style: techno(8, color: kTextDim, letterSpacing: 1.5)),
        ]),
      ]),
    );
  }

  Widget _board(GameState st) {
    final size = MediaQuery.of(context).size;
    final boardSize = (size.width - 32).clamp(0.0, size.height * 0.46);
    final cell = boardSize / st.level.size;

    return Container(
      width: boardSize + 10,
      height: boardSize + 10,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kSurface.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: GestureDetector(
        onTapUp: (d) {
          final c = (d.localPosition.dx / cell).floor();
          final r = (d.localPosition.dy / cell).floor();
          if (r < 0 ||
              c < 0 ||
              r >= st.level.size ||
              c >= st.level.size) {
            return;
          }
          _haptic();
          st.tapBoard(r * st.level.size + c);
        },
        child: CustomPaint(
          size: Size(boardSize, boardSize),
          painter: BoardPainter(st),
        ),
      ),
    );
  }

  Widget _tray(GameState st) {
    final unplaced =
        st.level.pieces.where((p) => !st.isPlaced(p.id)).toList();
    if (unplaced.isEmpty) {
      return Center(
          child: Text('ALL PIECES PLACED',
              style: techno(11, color: kTextDim, letterSpacing: 2)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (final p in unplaced)
            GestureDetector(
              onTap: () {
                _haptic();
                st.selectPiece(p.id);
              },
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: st.selectedPiece == p.id
                          ? kBlueprint
                          : kBorder,
                      width: st.selectedPiece == p.id ? 2 : 1),
                  boxShadow: st.selectedPiece == p.id
                      ? [
                          BoxShadow(
                              color: kAccent.withOpacity(0.3),
                              blurRadius: 14)
                        ]
                      : null,
                ),
                child: CustomPaint(
                  painter: PiecePainter(
                    piece: p,
                    color: kPieceColors[p.id % kPieceColors.length],
                    selected: st.selectedPiece == p.id,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(GameState st) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionBtn(Icons.refresh_rounded, 'RESTART', () {
            _victoryCtrl.reset();
            st.restartLevel();
          }),
          const SizedBox(width: 24),
          _actionBtn(Icons.grid_view_rounded, 'LEVELS', () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const LevelSelectScreen()));
          }),
        ],
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: kTextDim, size: 16),
            const SizedBox(width: 6),
            Text(label, style: techno(10, color: kTextDim, letterSpacing: 2)),
          ]),
        ),
      );

  Widget _victory(GameState st) => Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: ScaleTransition(
            scale: _victoryAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: kAccent.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 4)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccent.withOpacity(0.12),
                    border: Border.all(color: kAccent, width: 2),
                  ),
                  child: const Icon(Icons.extension_rounded,
                      color: kAccent, size: 30),
                ),
                const SizedBox(height: 16),
                Text('BLUEPRINT COMPLETE',
                    style: techno(15,
                        color: kAccent,
                        weight: FontWeight.w900,
                        letterSpacing: 3)),
                const SizedBox(height: 6),
                Text(
                    '${st.placements} PLACEMENTS  ·  PAR ${st.parMoves}',
                    style: techno(11, color: kTextDim, letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (i) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < st.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < st.stars ? kStarOn : kStarOff,
                              size: 36,
                            ),
                          )),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: _vBtn('REPLAY', Icons.refresh_rounded, false, () {
                    _victoryCtrl.reset();
                    st.restartLevel();
                  })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _vBtn('NEXT', Icons.arrow_forward_rounded, true,
                          () {
                    _victoryCtrl.reset();
                    if (st.currentLevelIndex < 149) {
                      st.nextLevel();
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const LevelSelectScreen()));
                    }
                  })),
                ]),
              ]),
            ),
          ),
        ),
      );

  Widget _vBtn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF2779C9), Color(0xFF4FA3E8)])
                : null,
            color: primary ? null : kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.5) : kBorder),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: techno(12, letterSpacing: 2)),
          ]),
        ),
      );
}
