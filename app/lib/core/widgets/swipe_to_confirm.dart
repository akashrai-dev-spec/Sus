import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../platform/platform_feedback.dart';
import '../theme/sus_colors.dart';
import '../theme/sus_typography.dart';

class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.enabled = true,
    this.height = 58,
  });

  final String label;
  final VoidCallback onConfirm;
  final bool enabled;
  final double height;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _dragPosition = 0;
  bool _isDragging = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _triggerAction() {
    if (!widget.enabled) return;
    PlatformFeedback.lightImpact();
    widget.onConfirm();
    _reset();
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _dragPosition = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDisabled = !widget.enabled;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: '${widget.label}, slide right or press Enter to confirm',
      onTap: widget.enabled ? _triggerAction : null,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (!widget.enabled) return KeyEventResult.ignored;
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _triggerAction();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final knobSize = widget.height - 8;
              final maxDrag = trackWidth - knobSize - 8;

              final currentDrag = _isDragging
                  ? _dragPosition
                  : _animController.value * maxDrag;
              final progress = maxDrag > 0 ? (currentDrag / maxDrag).clamp(0.0, 1.0) : 0.0;
              final labelOpacity = (1.0 - progress * 1.3).clamp(0.0, 1.0);

              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: _focusNode.hasFocus
                      ? Border.all(color: colors.crimsonBright, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Base track in crimson
                      Container(
                        color: colors.crimson,
                      ),

                      // Progressive fill in crimsonBright
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: (knobSize + 8 + currentDrag).clamp(0.0, trackWidth),
                        child: Container(
                          color: colors.crimsonBright,
                        ),
                      ),

                      // Label and chevrons
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Opacity(
                            opacity: labelOpacity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    style: SusTypography.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Opacity(
                                  opacity: 0.6,
                                  child: Text(
                                    '›››',
                                    style: SusTypography.body.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Draggable Knob
                      Positioned(
                        left: 4 + currentDrag,
                        top: 4,
                        child: GestureDetector(
                          onHorizontalDragStart: isDisabled
                              ? null
                              : (_) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragPosition = 0;
                                  });
                                },
                          onHorizontalDragUpdate: isDisabled
                              ? null
                              : (details) {
                                  setState(() {
                                    _dragPosition = (_dragPosition + details.delta.dx)
                                        .clamp(0.0, maxDrag);
                                  });
                                },
                          onHorizontalDragEnd: isDisabled
                              ? null
                              : (_) {
                                  if (_dragPosition >= maxDrag * 0.85) {
                                    _triggerAction();
                                  } else {
                                    _animController.value = _dragPosition / maxDrag;
                                    _animController.animateTo(
                                      0.0,
                                      curve: Curves.easeOutBack,
                                    );
                                    _reset();
                                  }
                                },
                          child: MouseRegion(
                            cursor: isDisabled
                                ? SystemMouseCursors.forbidden
                                : SystemMouseCursors.grab,
                            child: Container(
                              width: knobSize,
                              height: knobSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '›',
                                  style: TextStyle(
                                    color: colors.crimson,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
