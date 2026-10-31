import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/sus_colors.dart';
import '../../../core/theme/sus_typography.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/content_column.dart';
import '../../profile/presentation/profile_controller.dart';

class ModeScreen extends ConsumerWidget {
  const ModeScreen({super.key});

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
              'Pick how to play',
              style: SusTypography.title.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              'You’re playing as ${profile.name}.',
              style: SusTypography.body.copyWith(color: colors.mute),
            ),
            const SizedBox(height: 24),

            // Choice 1: Join a game
            _buildChoiceCard(
              context: context,
              colors: colors,
              title: 'Join a game',
              subtitle: 'Browse open rooms and enter with a 4-digit PIN',
              onTap: () => context.push('/rooms'),
            ),
            const SizedBox(height: 14),

            // Choice 2: Create a game
            _buildChoiceCard(
              context: context,
              colors: colors,
              title: 'Create a game',
              subtitle: 'Set the rules and share your PIN with friends',
              onTap: () => context.push('/create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required SusColors colors,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: SusTypography.heading.copyWith(color: colors.bone),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: SusTypography.caption.copyWith(color: colors.mute),
            ),
          ],
        ),
      ),
    );
  }
}
