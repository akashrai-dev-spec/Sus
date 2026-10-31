import 'package:flutter/material.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';
import 'player_avatar.dart';

class ClueBubble extends StatelessWidget {
  const ClueBubble({
    super.key,
    required this.playerName,
    required this.playerColorHex,
    required this.text,
    this.isSystem = false,
  });

  final String playerName;
  final String playerColorHex;
  final String text;
  final bool isSystem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            text,
            style: SusTypography.caption.copyWith(
              color: colors.crimsonBright,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayerAvatar(
            name: playerName,
            colorHex: playerColorHex,
            size: 32,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.panel,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: colors.line, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: SusTypography.caption.copyWith(
                      color: colors.mute,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: SusTypography.body.copyWith(
                      color: colors.bone,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
