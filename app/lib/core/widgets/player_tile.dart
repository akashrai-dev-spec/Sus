import 'package:flutter/material.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';
import 'player_avatar.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.name,
    required this.colorHex,
    this.isHost = false,
    this.isAlive = true,
    this.isSpeaking = false,
    this.isYou = false,
    this.trailingPill,
    this.trailingPillColor,
    this.onTap,
  });

  final String name;
  final String colorHex;
  final bool isHost;
  final bool isAlive;
  final bool isSpeaking;
  final bool isYou;
  final String? trailingPill;
  final Color? trailingPillColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSpeaking ? colors.panel : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSpeaking
            ? Border.all(color: colors.crimsonBright, width: 1.5)
            : Border(bottom: BorderSide(color: colors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isAlive ? 1.0 : 0.4,
            child: PlayerAvatar(
              name: name,
              colorHex: colorHex,
              size: 36,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name${isYou ? ' (you)' : ''}',
              style: SusTypography.body.copyWith(
                color: isAlive ? colors.bone : colors.mute,
                fontWeight: isSpeaking ? FontWeight.w700 : FontWeight.w500,
                decoration: isAlive ? null : TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSpeaking) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.crimson,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'speaking',
                style: SusTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else if (trailingPill != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trailingPillColor ?? Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                trailingPill!,
                style: SusTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else if (isHost) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'host',
                style: SusTypography.caption.copyWith(
                  color: colors.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: isAlive ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }
}
