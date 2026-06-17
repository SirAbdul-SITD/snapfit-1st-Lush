// lib/game/painters.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'fit_level.dart';
import 'game_state.dart';
import '../utils/constants.dart';

/// Blueprint board: chalk grid + placed pieces as rounded colored blocks.
class BoardPainter extends CustomPainter {
  final GameState st;
  BoardPainter(this.st);

  @override
  void paint(Canvas canvas, Size size) {
    final s = st.level.size;
    final cell = size.width / s;

    // blueprint fine grid
    final gp = Paint()
      ..color = kGridLine
      ..strokeWidth = 1;
    for (int i = 0; i <= s; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), gp);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), gp);
    }
    // dashed chalk outline
    final op = Paint()
      ..color = kBlueprint.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dash = 9.0;
    for (final horiz in [true, false]) {
      for (final far in [false, true]) {
        double t = 0;
        final len = horiz ? size.width : size.height;
        while (t < len) {
          final a = horiz
              ? Offset(t, far ? size.height : 0)
              : Offset(far ? size.width : 0, t);
          final b = horiz
              ? Offset((t + dash).clamp(0, len), far ? size.height : 0)
              : Offset(far ? size.width : 0, (t + dash).clamp(0, len));
          canvas.drawLine(a, b, op);
          t += dash * 2;
        }
      }
    }

    // placed pieces
    for (int i = 0; i < st.board.length; i++) {
      final id = st.board[i];
      if (id == -1) continue;
      final r = i ~/ s, c = i % s;
      final color = kPieceColors[id % kPieceColors.length];
      final rect =
          Rect.fromLTWH(c * cell + 2, r * cell + 2, cell - 4, cell - 4);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()..color = color);
      // join with same-piece neighbours so pieces read as one shape
      final fill = Paint()..color = color;
      if (c + 1 < s && st.board[i + 1] == id) {
        canvas.drawRect(
            Rect.fromLTWH((c + 1) * cell - 3, r * cell + 2, 6, cell - 4),
            fill);
      }
      if (r + 1 < s && st.board[i + s] == id) {
        canvas.drawRect(
            Rect.fromLTWH(c * cell + 2, (r + 1) * cell - 3, cell - 4, 6),
            fill);
      }
      // subtle top highlight
      canvas.drawLine(
          rect.topLeft + const Offset(3, 2),
          rect.topRight + const Offset(-3, 2),
          Paint()
            ..color = Colors.white.withOpacity(0.30)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}

/// One piece drawn in the tray (or as a thumbnail).
class PiecePainter extends CustomPainter {
  final FitPiece piece;
  final Color color;
  final bool selected;
  final bool used;

  PiecePainter(
      {required this.piece,
      required this.color,
      this.selected = false,
      this.used = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cols = piece.width, rows = piece.height;
    final cell = (size.width / cols < size.height / rows)
        ? size.width / cols
        : size.height / rows;
    final ox = (size.width - cols * cell) / 2;
    final oy = (size.height - rows * cell) / 2;

    final c = used ? color.withOpacity(0.18) : color;
    final inPiece = piece.cells.toSet();
    for (final p in piece.cells) {
      final rect = Rect.fromLTWH(
          ox + p.y * cell + 1.5, oy + p.x * cell + 1.5, cell - 3, cell - 3);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = c);
      final fill = Paint()..color = c;
      if (inPiece.contains(Point(p.x, p.y + 1))) {
        canvas.drawRect(
            Rect.fromLTWH(ox + (p.y + 1) * cell - 2, oy + p.x * cell + 1.5,
                4, cell - 3),
            fill);
      }
      if (inPiece.contains(Point(p.x + 1, p.y))) {
        canvas.drawRect(
            Rect.fromLTWH(ox + p.y * cell + 1.5, oy + (p.x + 1) * cell - 2,
                cell - 3, 4),
            fill);
      }
    }
    if (selected) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
              const Radius.circular(8)),
          Paint()
            ..color = kBlueprint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.selected != selected || old.used != used || old.piece != piece;
}
