import 'package:flutter/material.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';

class TurnIndicator extends StatelessWidget {
  const TurnIndicator({
    super.key,
    required this.roundText,
    required this.category,
    this.trailing,
  });

  final String roundText;
  final String category;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: colors.line, width: 1),
                ),
                child: Text(
                  roundText,
                  style: SusTypography.caption.copyWith(
                    color: colors.bone,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: colors.line, width: 1),
                ),
                child: Text(
                  category,
                  style: SusTypography.caption.copyWith(
                    color: colors.mute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
