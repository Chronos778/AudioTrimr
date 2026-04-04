import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme.dart';

enum HandleType { start, end }

class TrimHandle extends StatefulWidget {
  final HandleType type;
  final double position;
  final double containerWidth;
  final double containerHeight;
  final double nudgeFraction;
  final ValueChanged<double> onDrag;
  final ValueChanged<double>? onNudge;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const TrimHandle({
    super.key,
    required this.type,
    required this.position,
    required this.containerWidth,
    required this.containerHeight,
    required this.onDrag,
    this.nudgeFraction = 0.01,
    this.onNudge,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<TrimHandle> createState() => _TrimHandleState();
}

class _TrimHandleState extends State<TrimHandle> {
  bool _focused = false;
  bool _hovered = false;

  Color get _color => AppTheme.accentBlue;

  String get _label =>
      widget.type == HandleType.start ? 'Start trim handle' : 'End trim handle';

  String get _hint => widget.type == HandleType.start
      ? 'Use left and right arrow keys to move the start boundary'
      : 'Use left and right arrow keys to move the end boundary';

  void _nudge(double delta) {
    widget.onNudge?.call(delta);
  }

  @override
  Widget build(BuildContext context) {
    const handleWidth = 18.0;
    final xPos = (widget.position * widget.containerWidth) - handleWidth / 2;

    return Positioned(
      left: xPos.clamp(0.0, widget.containerWidth - handleWidth),
      top: 0,
      child: Semantics(
        button: true,
        focusable: true,
        label: _label,
        hint: _hint,
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _nudge(-widget.nudgeFraction);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nudge(widget.nudgeFraction);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              HapticFeedback.selectionClick();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                HapticFeedback.selectionClick();
                widget.onDragStart?.call();
              },
              onHorizontalDragUpdate: (details) {
                final newPos =
                    ((xPos + handleWidth / 2 + details.delta.dx) / widget.containerWidth)
                        .clamp(0.0, 1.0);
                widget.onDrag(newPos);
              },
              onHorizontalDragEnd: (_) {
                HapticFeedback.selectionClick();
                widget.onDragEnd?.call();
              },
              child: SizedBox(
                width: handleWidth,
                height: widget.containerHeight,
                child: AnimatedContainer(
                  duration: AppTheme.microDuration,
                  curve: AppTheme.easeOutSmooth,
                  decoration: BoxDecoration(
                    boxShadow: _focused || _hovered
                        ? [
                            BoxShadow(
                              color: _color.withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                  ),
                  child: CustomPaint(
                    painter: _HandlePainter(
                      color: _color,
                      focused: _focused,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  final Color color;
  final bool focused;

  _HandlePainter({required this.color, required this.focused});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = focused ? 4.0 : 2.0;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    
    // Main boundary line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      linePaint,
    );

    // Head block top
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, 10), width: 14, height: 20),
      headPaint,
    );

    // Head block bottom
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, size.height - 10), width: 14, height: 20),
      headPaint,
    );

    // Geometric arrows inside blocks if focused
    if (focused) {
      final textPaint = Paint()..color = AppTheme.bgPrimary;
      canvas.drawLine(Offset(centerX - 3, 10), Offset(centerX + 3, 10), textPaint..strokeWidth = 2);
      canvas.drawLine(Offset(centerX - 3, size.height - 10), Offset(centerX + 3, size.height - 10), textPaint..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _HandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.focused != focused;
  }
}

