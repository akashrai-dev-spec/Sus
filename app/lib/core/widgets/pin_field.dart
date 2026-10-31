import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';

class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final TextEditingController? controller;

  @override
  State<PinField> createState() => PinFieldState();
}

class PinFieldState extends State<PinField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChange);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  void _handleTextChange() {
    widget.onChanged(_controller.text);
    if (_controller.text.length == 4) {
      widget.onCompleted?.call(_controller.text);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void shake() {
    _shakeController.forward(from: 0.0);
  }

  void clear() {
    _controller.clear();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _shakeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = _controller.text;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden text field capturing numbers
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  autofocus: true,
                ),
              ),
            ),

            // Visible 4 PIN digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < text.length;
                final isCurrent = index == text.length;
                final digit = isFilled ? text[index] : '';

                return Container(
                  width: 54,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: colors.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent && _focusNode.hasFocus
                          ? colors.crimsonBright
                          : isFilled
                              ? colors.crimson
                              : colors.line,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: SusTypography.title.copyWith(
                        color: colors.bone,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
