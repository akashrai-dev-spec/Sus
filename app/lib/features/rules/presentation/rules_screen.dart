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

    final rules = [
      (
        '1',
        'Swipe to confirm',
        'Slide the crimson bars to the right to confirm an action. This deliberate gesture prevents accidental taps during intense party moments.',
      ),
      (
        '2',
        'Hidden roles',
        'Each round secretly assigns 1 to 3 imposters. Everyone else is a normal player. The room is locked with a 4-digit PIN.',
      ),
      (
        '3',
        'The secret word',
        'Normal players see the secret word. The imposter sees only the category. The imposter must bluff and blend in.',
      ),
      (
        '4',
        'Turn-based clues',
        'Players take turns in a fixed speaking order giving one clue about the word. Nobody may say the secret word itself.',
      ),
      (
        '5',
        'Immediate accusation',
        'Instead of shouting, any alive player with an unused accusation can press Accuse. The game pauses and the accused role is dramatically revealed. If they are an imposter, they are out. If normal, the accuser loses their accusation.',
      ),
      (
        '6',
        'Imposter word guess',
        'At any time, an imposter can attempt to guess the secret word. A correct guess means the imposters win immediately!',
      ),
      (
        '7',
        'The final vote',
        'After all discussion rounds conclude, the group conducts a final vote. A wrong final accusation means the imposter wins.',
      ),
    ];

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
            const SizedBox(height: 6),
            Text(
              'Master the rules of deception, deductions, and wordplay.',
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final (num, title, desc) = rules[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.line, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colors.crimson,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              num,
                              style: SusTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
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
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.crimson,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Got it',
                style: SusTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
