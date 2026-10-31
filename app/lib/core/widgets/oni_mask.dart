import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/sus_colors.dart';

class OniMask extends StatelessWidget {
  const OniMask({
    super.key,
    this.size = 120,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colors.crimson;

    return SvgPicture.asset(
      'assets/brand/mask.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      placeholderBuilder: (context) => SizedBox(
        width: size,
        height: size,
      ),
    );
  }
}
