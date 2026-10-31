import 'package:flutter/material.dart';
import '../theme/sus_typography.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.colorHex,
    this.size = 38,
    this.onTap,
  });

  final String name;
  final String colorHex;
  final double size;
  final VoidCallback? onTap;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF9A0F28);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final bgColor = _parseColor(colorHex);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: SusTypography.fontFamily,
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: avatar,
        ),
      );
    }

    return avatar;
  }
}
