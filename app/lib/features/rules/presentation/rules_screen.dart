import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/content_column.dart';
import '../../profile/presentation/profile_controller.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppHeader(
        playerName: profile.name,
        playerColorHex: profile.color,
      ),
      body: ContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Sus works',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 4),
            Text(
              'One word. One imposter. Can you spot the fake?',
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Roles Split Card
                    Row(
                      children: [
                        // Normal Role Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.panel,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.win.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.win,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NORMALS',
                                      style: SusTypography.caption.copyWith(
                                        color: colors.win,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Know the word',
                                  style: SusTypography.body.copyWith(
                                    color: colors.bone,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Give clues that prove you know it without giving it away.',
                                  style: SusTypography.caption.copyWith(
                                    color: colors.mute,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Imposter Role Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.panel,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.crimsonBright.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.crimsonBright,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'IMPOSTER',
                                      style: SusTypography.caption.copyWith(
                                        color: colors.crimsonBright,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Only category',
                                  style: SusTypography.body.copyWith(
                                    color: colors.bone,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bluff your clues, listen to others, and guess the word.',
                                  style: SusTypography.caption.copyWith(
                                    color: colors.mute,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stage 1
                    _buildStepCard(
                      colors: colors,
                      step: '1',
                      icon: Icons.lock_outline_rounded,
                      title: 'Secret word distribution',
                      desc:
                          'When the match starts, players secretly inspect their role card. Normal players receive the secret word (e.g. Pizza). The imposter sees only the category (e.g. Objects & Food).',
                    ),
                    const SizedBox(height: 10),

                    // Stage 2
                    _buildStepCard(
                      colors: colors,
                      step: '2',
                      icon: Icons.record_voice_over_rounded,
                      title: 'The clue round',
                      desc:
                          'Players take turns in a randomized speaking order giving one clue out loud. You can say anything, but saying the secret word itself is strictly forbidden!',
                    ),
                    const SizedBox(height: 10),

                    // Stage 3
                    _buildStepCard(
                      colors: colors,
                      step: '3',
                      icon: Icons.gavel_rounded,
                      title: 'Sudden-death accusations',
                      desc:
                          'Notice someone bluffing? Hit Accuse! The game pauses and their identity is revealed. Catch an imposter and they are eliminated. Make a false call and you lose your accusation permanently.',
                    ),
                    const SizedBox(height: 10),

                    // Stage 4
                    _buildStepCard(
                      colors: colors,
                      step: '4',
                      icon: Icons.psychology_rounded,
                      title: 'The imposter guess',
                      desc:
                          'If an imposter decodes the secret word from everyone’s clues, they can attempt a guess. Guessing correctly triggers an immediate, dramatic imposter victory!',
                    ),
                    const SizedBox(height: 10),

                    // Stage 5
                    _buildStepCard(
                      colors: colors,
                      step: '5',
                      icon: Icons.flag_rounded,
                      title: 'The final vote',
                      desc:
                          'If all discussion rounds finish and the imposter survives, the group makes one final accusation. Guess wrong, and the imposter wins the match.',
                    ),

                    const SizedBox(height: 16),

                    // Pro-tip card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.panel.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.line, width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_rounded, color: colors.crimsonBright, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro Tip',
                                  style: SusTypography.body.copyWith(
                                    color: colors.bone,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'If your clue is too obvious, the imposter will steal the word. If your clue is too vague, the room will suspect you. Balance is everything.',
                                  style: SusTypography.caption.copyWith(
                                    color: colors.mute,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.crimson,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Got it, let’s play',
                style: SusTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required SusColors colors,
    required String step,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.crimson.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.crimson.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: colors.crimsonBright, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SusTypography.body.copyWith(
                    color: colors.bone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: SusTypography.caption.copyWith(
                    color: colors.mute,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
