import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/content_column.dart';
import '../../../core/widgets/oni_mask.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../../profile/presentation/profile_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppHeader(
        isHome: true,
        playerName: profile.name,
        playerColorHex: profile.color,
      ),
      body: ContentColumn(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Large Oni Mask Centerpiece (no circle)
            Center(
              child: OniMask(
                size: 156,
                color: colors.crimson,
              ),
            )
                .animate()
                .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 28),

            // Main Tagline
            Text(
              'One word.\nOne imposter.',
              style: SusTypography.display.copyWith(
                color: colors.bone,
                height: 1.12,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // Subtitle description
            Text(
              'Normal players know the secret word.\nThe imposter bluffs to survive.',
              style: SusTypography.body.copyWith(
                color: colors.mute,
                fontSize: 15,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const Spacer(flex: 3),

                // Active profile quick card
                InkWell(
                  onTap: () => context.push('/profile'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: colors.panel.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.line, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatar(
                          name: profile.name,
                          colorHex: profile.color,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Playing as ',
                          style: SusTypography.caption.copyWith(color: colors.mute),
                        ),
                        Flexible(
                          child: Text(
                            profile.name,
                            style: SusTypography.caption.copyWith(
                              color: colors.bone,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: colors.mute,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // Play action slider
                SwipeToConfirm(
                  label: 'Swipe to play',
                  onConfirm: () => context.push('/mode'),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Sleek dark "How to play" secondary button
                OutlinedButton.icon(
                  onPressed: () => context.push('/rules'),
                  icon: const Icon(Icons.help_outline_rounded, size: 20),
                  label: const Text('How to play'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colors.panel,
                    foregroundColor: colors.bone,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: colors.line, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: SusTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 16),

                // Compliance & Legal Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Terms',
                        style: SusTypography.caption.copyWith(
                          color: colors.mute,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text('•', style: TextStyle(color: colors.mute, fontSize: 10)),
                    TextButton(
                      onPressed: () => context.push('/privacy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Privacy',
                        style: SusTypography.caption.copyWith(
                          color: colors.mute,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text('•', style: TextStyle(color: colors.mute, fontSize: 10)),
                    TextButton(
                      onPressed: () => context.push('/legal'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Legal Notice',
                        style: SusTypography.caption.copyWith(
                          color: colors.mute,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }
}
