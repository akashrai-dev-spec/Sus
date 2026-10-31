import 'package:flutter/material.dart';
import '../theme/sus_colors.dart';

class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.maxWidth = 480,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.ink,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
