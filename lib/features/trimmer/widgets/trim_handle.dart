import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme.dart';

enum HandleType { start, end }

class TrimHandle extends StatelessWidget {
  final HandleType type;
  final double position; // 0.0 to 1.0
  final double containerWidth;
  final double containerHeight;
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const TrimHandle({
    super.key,
    required this.type,
    required this.position,
    required this.containerWidth,
    required this.containerHeight,
    required this.onDrag,
    this.onDragStart,
    this.onDragEnd,
  });

  Color get _color =>
      type == HandleType.start ? AppTheme.accentGreen : AppTheme.accentRed;

  @override
  Widget build(BuildContext context) {
    final handleWidth = 18.0;
    final xPos = (position * containerWidth) - handleWidth / 2;

    return Positioned(
      left: xPos.clamp(0.0, containerWidth - handleWidth),
      top: 0,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          HapticFeedback.selectionClick();
          onDragStart?.call();
        },
        onHorizontalDragUpdate: (details) {
          final newPos =
              ((xPos + handleWidth / 2 + details.delta.dx) / containerWidth)
                  .clamp(0.0, 1.0);
          onDrag(newPos);
        },
        onHorizontalDragEnd: (_) {
          HapticFeedback.selectionClick();
          onDragEnd?.call();
        },
        child: SizedBox(
          width: handleWidth,
          height: containerHeight,
          child: CustomPaint(
            painter: _HandlePainter(
              color: _color,
              type: type,
            ),
          ),
        ),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  final Color color;
  final HandleType type;

  _HandlePainter({required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw the vertical line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      linePaint,
    );

    // Draw handle grip at top
    final gripRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, 14),
        width: 14,
        height: 20,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(gripRect, paint);

    // Draw grip lines
    final gripLinePaint = Paint()
      ..color = AppTheme.bgPrimary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = -1; i <= 1; i++) {
      final y = 14.0 + i * 4.0;
      canvas.drawLine(
        Offset(centerX - 3, y),
        Offset(centerX + 3, y),
        gripLinePaint,
      );
    }

    // Draw handle grip at bottom
    final bottomGrip = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height - 14),
        width: 14,
        height: 20,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bottomGrip, paint);

    for (int i = -1; i <= 1; i++) {
      final y = size.height - 14.0 + i * 4.0;
      canvas.drawLine(
        Offset(centerX - 3, y),
        Offset(centerX + 3, y),
        gripLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.type != type;
  }
}
