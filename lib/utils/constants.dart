// lib/utils/constants.dart
import 'package:flutter/material.dart';

// ── SnapFit palette: drafting blueprint + vivid puzzle pieces ───────────
const Color kBg          = Color(0xFF0A1F33);
const Color kSurface     = Color(0xFF11283F);
const Color kBorder      = Color(0xFF234866);
const Color kGridLine    = Color(0xFF1A3A55);
const Color kAccent      = Color(0xFF6EC6FF); // blueprint cyan
const Color kBlueprint   = Color(0xFFDCEAF5); // chalk white
const Color kTextPrimary = Color(0xFFE9F3FB);
const Color kTextDim     = Color(0xFF7FA0BB);

const Color kStarOn  = Color(0xFFFFD54F);
const Color kStarOff = Color(0xFF1C3850);

const Color kEasyColor   = Color(0xFF6EC6FF);
const Color kMediumColor = Color(0xFFB388FF);
const Color kHardColor   = Color(0xFFFF7043);

/// Piece colors — assigned to pieces in order
const List<Color> kPieceColors = [
  Color(0xFFFF5252),
  Color(0xFFFFA726),
  Color(0xFFFFEE58),
  Color(0xFF66BB6A),
  Color(0xFF26C6DA),
  Color(0xFF42A5F5),
  Color(0xFF7C4DFF),
  Color(0xFFFF4081),
  Color(0xFFB2FF59),
  Color(0xFF26A69A),
  Color(0xFFFFCA28),
  Color(0xFFEC407A),
  Color(0xFF5C6BC0),
  Color(0xFF9CCC65),
  Color(0xFFFF8A65),
  Color(0xFF4DD0E1),
];

const int kTotalLevels = 150;

TextStyle techno(double size,
        {Color color = kTextPrimary,
        FontWeight weight = FontWeight.bold,
        double letterSpacing = 1.5}) =>
    TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing);
