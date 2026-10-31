import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';
import 'oni_mask.dart';
import 'player_avatar.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.isHome = false,
    this.showBack = true,
    this.onBack,
    required this.playerName,
    required this.playerColorHex,
  });

  final bool isHome;
  final bool showBack;
  final VoidCallback? onBack;
  final String playerName;
  final String playerColorHex;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isHome)
                OniMask(size: 38, color: colors.crimson)
              else if (showBack)
                IconButton(
                  onPressed: onBack ?? () => context.pop(),
                  icon: Text(
                    '‹',
                    style: TextStyle(
                      fontFamily: SusTypography.fontFamily,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: colors.bone,
                      height: 0.8,
                    ),
                  ),
                )
              else
                const SizedBox(width: 38),
              PlayerAvatar(
                name: playerName,
                colorHex: playerColorHex,
                size: 38,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
