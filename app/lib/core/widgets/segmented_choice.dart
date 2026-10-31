import 'package:flutter/material.dart';
import '../platform/platform_feedback.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';

class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T item)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        final label = labelBuilder != null ? labelBuilder!(opt) : opt.toString();

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  PlatformFeedback.lightImpact();
                  onChanged(opt);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.crimson : colors.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.crimson : colors.line,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: SusTypography.body.copyWith(
                      color: isSelected ? Colors.white : colors.bone,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
