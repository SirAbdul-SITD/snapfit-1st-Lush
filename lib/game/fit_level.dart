// lib/game/fit_level.dart
import 'dart:math';

/// One puzzle piece: a normalized set of (row, col) offsets.
/// Offsets are shifted so minRow == 0 and minCol == 0; the anchor is
/// the first cell in row-major order.
class FitPiece {
  final int id;
  final List<Point<int>> cells;

  FitPiece(this.id, this.cells);

  int get width => cells.map((c) => c.y).reduce(max) + 1;
  int get height => cells.map((c) => c.x).reduce(max) + 1;
}

class FitLevel {
  final int index;
  final int size;
  final String difficulty;
  final List<FitPiece> pieces;

  FitLevel({
    required this.index,
    required this.size,
    required this.difficulty,
    required this.pieces,
  });
}

class LevelGenerator {
  static FitLevel generate(int levelIndex) {
    int size;
    String difficulty;
    if (levelIndex < 50) {
      size = 6;
      difficulty = 'Easy';
    } else if (levelIndex < 100) {
      size = 7;
      difficulty = 'Medium';
    } else {
      size = 8;
      difficulty = 'Hard';
    }

    final rng = Random(levelIndex * 7411 + levelIndex * 29 + 53);

    List<List<int>>? regions;
    for (int attempt = 0; attempt < 400; attempt++) {
      regions = _tryPartition(size, Random(rng.nextInt(1 << 31)));
      if (regions != null) break;
    }
    // fallback: rows split into halves
    regions ??= [
      for (int r = 0; r < size; r++) ...[
        List.generate(size ~/ 2, (c) => r * size + c),
        List.generate(size - size ~/ 2, (c) => r * size + size ~/ 2 + c),
      ]
    ];

    final pieces = <FitPiece>[];
    for (int p = 0; p < regions.length; p++) {
      final pts = regions[p]
          .map((i) => Point<int>(i ~/ size, i % size))
          .toList();
      final minR = pts.map((q) => q.x).reduce(min);
      final minC = pts.map((q) => q.y).reduce(min);
      final norm = pts
          .map((q) => Point<int>(q.x - minR, q.y - minC))
          .toList()
        ..sort((a, b) => a.x != b.x ? a.x - b.x : a.y - b.y);
      pieces.add(FitPiece(p, norm));
    }
    // present pieces in shuffled order so layout isn't a giveaway
    pieces.shuffle(rng);

    return FitLevel(
      index: levelIndex,
      size: size,
      difficulty: difficulty,
      pieces: pieces,
    );
  }

  /// Region-grow the grid into chunky polyominoes of size 3–5.
  static List<List<int>>? _tryPartition(int size, Random rng) {
    final total = size * size;
    final remaining = <int>{for (int i = 0; i < total; i++) i};
    final regions = <List<int>>[];

    while (remaining.isNotEmpty) {
      // seed at the cell with fewest free neighbours
      int start = -1, best = 9;
      for (final cell in remaining) {
        final n = _freeNbrs(cell, size, remaining).length;
        if (n < best) {
          best = n;
          start = cell;
          if (n <= 1) break;
        }
      }
      final target = 3 + rng.nextInt(3); // 3..5
      final region = <int>[start];
      remaining.remove(start);
      while (region.length < target) {
        // grow from a random cell of the region (allows L/T/S shapes)
        final frontier = <int>[];
        for (final cell in region) {
          frontier.addAll(_freeNbrs(cell, size, remaining));
        }
        if (frontier.isEmpty) break;
        final next = frontier[rng.nextInt(frontier.length)];
        region.add(next);
        remaining.remove(next);
      }
      if (region.length < 3) return null; // stranded scrap — retry
      regions.add(region);
    }
    if (regions.length < 4) return null;
    return regions;
  }

  static List<int> _freeNbrs(int i, int s, Set<int> remaining) {
    final r = i ~/ s, c = i % s;
    return [
      if (r > 0 && remaining.contains(i - s)) i - s,
      if (r < s - 1 && remaining.contains(i + s)) i + s,
      if (c > 0 && remaining.contains(i - 1)) i - 1,
      if (c < s - 1 && remaining.contains(i + 1)) i + 1,
    ];
  }
}
