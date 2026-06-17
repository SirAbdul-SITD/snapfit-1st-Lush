// lib/game/game_state.dart
import 'package:flutter/material.dart';
import 'fit_level.dart';
import '../utils/preferences.dart';
import '../utils/audio_manager.dart';

class GameState extends ChangeNotifier {
  late FitLevel level;
  /// board cell index -> piece id, or -1 if empty
  late List<int> board;
  /// piece id -> anchor board cell (or null if in tray)
  final Map<int, int> placed = {};
  int? selectedPiece;
  int placements = 0;
  bool isComplete = false;
  int stars = 0;
  int currentLevelIndex = 0;
  bool initialized = false;

  int get parMoves => level.pieces.length;

  void loadLevel(int index) {
    currentLevelIndex = index;
    level = LevelGenerator.generate(index);
    board = List.filled(level.size * level.size, -1);
    placed.clear();
    selectedPiece = null;
    placements = 0;
    isComplete = false;
    stars = 0;
    initialized = true;
    notifyListeners();
  }

  FitPiece pieceById(int id) =>
      level.pieces.firstWhere((p) => p.id == id);

  bool isPlaced(int id) => placed.containsKey(id);

  void selectPiece(int id) {
    if (isComplete || isPlaced(id)) return;
    selectedPiece = selectedPiece == id ? null : id;
    notifyListeners();
  }

  bool _fits(FitPiece p, int anchorR, int anchorC) {
    final s = level.size;
    for (final cell in p.cells) {
      final r = anchorR + cell.x, c = anchorC + cell.y;
      if (r < 0 || c < 0 || r >= s || c >= s) return false;
      if (board[r * s + c] != -1) return false;
    }
    return true;
  }

  void _place(FitPiece p, int anchorR, int anchorC) {
    final s = level.size;
    for (final cell in p.cells) {
      board[(anchorR + cell.x) * s + (anchorC + cell.y)] = p.id;
    }
    placed[p.id] = anchorR * s + anchorC;
    placements++;
    selectedPiece = null;
    AudioManager.instance.playSnap();
    _checkComplete();
  }

  /// Tap on the board: place the selected piece (forgiving anchoring —
  /// tries to interpret the tap as any cell of the piece), or lift a
  /// placed piece back to the tray.
  void tapBoard(int boardIndex) {
    if (isComplete) return;
    final s = level.size;
    final r = boardIndex ~/ s, c = boardIndex % s;

    if (selectedPiece != null) {
      final p = pieceById(selectedPiece!);
      // try: tapped cell = each cell of the piece, anchor-first
      for (final cell in p.cells) {
        final ar = r - cell.x, ac = c - cell.y;
        if (_fits(p, ar, ac)) {
          _place(p, ar, ac);
          notifyListeners();
          return;
        }
      }
      // no fit — fall through to maybe lifting a piece under the tap
    }

    final occupant = board[boardIndex];
    if (occupant != -1) {
      _lift(occupant);
    }
    notifyListeners();
  }

  void _lift(int id) {
    // ignore: unused_local_variable
    final s = level.size;
    for (int i = 0; i < board.length; i++) {
      if (board[i] == id) board[i] = -1;
    }
    placed.remove(id);
    selectedPiece = id;
  }

  void _checkComplete() {
    if (board.every((b) => b != -1) && !isComplete) {
      isComplete = true;
      stars = _calcStars();
      AudioManager.instance.playComplete();
      Preferences.instance.saveLevelResult(currentLevelIndex, stars);
    }
  }

  int _calcStars() {
    if (placements <= parMoves) return 3;
    if (placements <= (parMoves * 1.6).round()) return 2;
    return 1;
  }

  void restartLevel() => loadLevel(currentLevelIndex);

  void nextLevel() {
    if (currentLevelIndex < 149) loadLevel(currentLevelIndex + 1);
  }
}
