import 'package:flutter/material.dart';

@immutable
class SusColors extends ThemeExtension<SusColors> {
  const SusColors({
    required this.ink,
    required this.panel,
    required this.line,
    required this.crimson,
    required this.crimsonBright,
    required this.bone,
    required this.mute,
    required this.ash,
    required this.win,
    required this.lose,
  });

  final Color ink;
  final Color panel;
  final Color line;
  final Color crimson;
  final Color crimsonBright;
  final Color bone;
  final Color mute;
  final Color ash;
  final Color win;
  final Color lose;

  static const dark = SusColors(
    ink: Color(0xFF161616),
    panel: Color(0xFF222222),
    line: Color(0xFF333333),
    crimson: Color(0xFF9A0F28),
    crimsonBright: Color(0xFFB5173A),
    bone: Color(0xFFF4F4F4),
    mute: Color(0xFF9A9A9A),
    ash: Color(0xFFD9D9D9),
    win: Color(0xFF6FD08C),
    lose: Color(0xFFB5173A),
  );

  static const light = SusColors(
    ink: Color(0xFFF8F8F8),
    panel: Color(0xFFEBEBEB),
    line: Color(0xFFD0D0D0),
    crimson: Color(0xFF9A0F28),
    crimsonBright: Color(0xFFB5173A),
    bone: Color(0xFF161616),
    mute: Color(0xFF666666),
    ash: Color(0xFF2E2E2E),
    win: Color(0xFF2E7D32),
    lose: Color(0xFFB5173A),
  );

  @override
  SusColors copyWith({
    Color? ink,
    Color? panel,
    Color? line,
    Color? crimson,
    Color? crimsonBright,
    Color? bone,
    Color? mute,
    Color? ash,
    Color? win,
    Color? lose,
  }) {
    return SusColors(
      ink: ink ?? this.ink,
      panel: panel ?? this.panel,
      line: line ?? this.line,
      crimson: crimson ?? this.crimson,
      crimsonBright: crimsonBright ?? this.crimsonBright,
      bone: bone ?? this.bone,
      mute: mute ?? this.mute,
      ash: ash ?? this.ash,
      win: win ?? this.win,
      lose: lose ?? this.lose,
    );
  }

  @override
  SusColors lerp(ThemeExtension<SusColors>? other, double t) {
    if (other is! SusColors) return this;
    return SusColors(
      ink: Color.lerp(ink, other.ink, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      line: Color.lerp(line, other.line, t)!,
      crimson: Color.lerp(crimson, other.crimson, t)!,
      crimsonBright: Color.lerp(crimsonBright, other.crimsonBright, t)!,
      bone: Color.lerp(bone, other.bone, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      ash: Color.lerp(ash, other.ash, t)!,
      win: Color.lerp(win, other.win, t)!,
      lose: Color.lerp(lose, other.lose, t)!,
    );
  }
}

extension BuildContextColors on BuildContext {
  SusColors get colors =>
      Theme.of(this).extension<SusColors>() ?? SusColors.dark;
}
