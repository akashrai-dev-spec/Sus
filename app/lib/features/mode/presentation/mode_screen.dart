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
            _ChoiceCard(
              title: 'Join a game',
              subtitle: 'Browse open rooms and enter with a 4-digit PIN',
              onTap: () => context.push('/rooms'),
            ),
            const SizedBox(height: 14),

            // Choice 2: Create a game
            _ChoiceCard(
              title: 'Create a game',
              subtitle: 'Set the rules and share your PIN with friends',
              onTap: () => context.push('/create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? colors.crimson : colors.line,
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colors.crimson.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: SusTypography.heading.copyWith(color: colors.bone),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: SusTypography.caption.copyWith(color: colors.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
