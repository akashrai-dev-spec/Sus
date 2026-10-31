import 'package:flutter/material.dart';
import '../platform/platform_feedback.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';

class RoleCard extends StatefulWidget {
  const RoleCard({
    super.key,
    required this.isImposter,
    required this.category,
    this.secretWord,
  });

  final bool isImposter;
  final String category;
  final String? secretWord;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isRevealed = false;

  void _onPressDown() {
    PlatformFeedback.lightImpact();
    setState(() => _isRevealed = true);
  }

  void _onPressUp() {
    if (_isRevealed) {
      setState(() => _isRevealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Listener(
      onPointerDown: (_) => _onPressDown(),
      onPointerUp: (_) => _onPressUp(),
      onPointerCancel: (_) => _onPressUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isRevealed ? colors.crimson : colors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isRevealed ? colors.crimsonBright : const Color(0xFF555555),
            width: 2,
          ),
          boxShadow: _isRevealed
              ? [
                  BoxShadow(
                    color: colors.crimson.withAlpha(80),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isRevealed ? _buildRevealedContent(colors) : _buildHiddenContent(colors),
        ),
      ),
    );
  }

  Widget _buildHiddenContent(SusColors colors) {
    return Column(
      key: const ValueKey('hidden'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.fingerprint_rounded,
          size: 56,
          color: colors.mute,
        ),
        const SizedBox(height: 14),
        Text(
          'Hold to reveal',
          style: SusTypography.heading.copyWith(color: colors.bone),
        ),
        const SizedBox(height: 6),
        Text(
          'Press and keep holding to see your secret',
          style: SusTypography.caption.copyWith(color: colors.mute),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRevealedContent(SusColors colors) {
    return Column(
      key: const ValueKey('revealed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isImposter) ...[
          Text(
            'You are the',
            style: SusTypography.body.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IMPOSTER',
            style: SusTypography.display.copyWith(
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Category: ${widget.category}',
            style: SusTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Blend in and work out the secret word.',
            style: SusTypography.caption.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Text(
            'The secret word is',
            style: SusTypography.body.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.secretWord ?? '',
            style: SusTypography.display.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Category: ${widget.category}',
            style: SusTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Describe it, but never say it.',
            style: SusTypography.caption.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
