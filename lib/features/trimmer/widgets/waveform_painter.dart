import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double trimStartFraction;
  final double trimEndFraction;
  final double playheadFraction;
  final double zoomLevel;
  final bool isPlaying;

  WaveformPainter({
    required this.samples,
    required this.trimStartFraction,
    required this.trimEndFraction,
    required this.playheadFraction,
    required this.zoomLevel,
    this.isPlaying = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final effectiveZoom = zoomLevel.clamp(1.0, 3.0);
    final zoomedWidth = size.width * effectiveZoom;
    final barWidth = max(1.0, (zoomedWidth / samples.length) - 1.0);
    final spacing = max(0.5, (zoomedWidth - barWidth * samples.length) / (samples.length - 1));
    final totalBarWidth = barWidth + spacing;
    final horizontalOffset = (size.width - zoomedWidth) / 2;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.85;

    final regionGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.accentElec.withValues(alpha: 0.22),
          AppTheme.accentGreen.withValues(alpha: 0.14),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), regionGlowPaint);

    // Paint for inactive (outside trim) bars
    final inactivePaint = Paint()
      ..color = AppTheme.waveformBase.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Paint for active (inside trim) bars
    final activePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Draw each bar
    for (int i = 0; i < samples.length; i++) {
      final x = horizontalOffset + i * totalBarWidth;
      final fraction = i / samples.length;
      final isInTrimRegion =
          fraction >= trimStartFraction && fraction <= trimEndFraction;

      final amplitude = samples[i].clamp(0.02, 1.0);
      final barHeight = max(2.0, amplitude * maxBarHeight);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );

      if (isInTrimRegion) {
        activePaint.color = Color.lerp(
          AppTheme.waveformActive.withValues(alpha: 0.72),
          AppTheme.waveformActive,
          amplitude,
        )!;

        if (playheadFraction > 0 && fraction <= _getAbsolutePlayhead()) {
          activePaint.color = Color.lerp(
            AppTheme.accentElec,
            AppTheme.waveformActive,
            0.35,
          )!;
        }

        canvas.drawRRect(rect, activePaint);
      } else {
        canvas.drawRRect(rect, inactivePaint);
      }
    }

    // Draw dim overlay outside trim region
    final overlayPaint = Paint()
      ..color = AppTheme.bgPrimary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Left overlay
    if (trimStartFraction > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, trimStartFraction * size.width, size.height),
        overlayPaint..color = AppTheme.bgPrimary.withValues(alpha: 0.62),
      );
    }

    // Right overlay
    if (trimEndFraction < 1.0) {
      canvas.drawRect(
        Rect.fromLTRB(
            trimEndFraction * size.width, 0, size.width, size.height),
        overlayPaint..color = AppTheme.bgPrimary.withValues(alpha: 0.62),
      );
    }

    if (isPlaying || playheadFraction > 0) {
      final playheadX = _getAbsolutePlayhead() * size.width;
      final playheadPaint = Paint()
        ..color = AppTheme.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      final glowPaint = Paint()
        ..color = AppTheme.accentElec.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;

      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        glowPaint,
      );

      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );

      canvas.drawCircle(
        Offset(playheadX, 3),
        4,
        Paint()..color = AppTheme.accentElec,
      );
    }
  }

  double _getAbsolutePlayhead() {
    // playheadFraction is relative to trim region
    return trimStartFraction +
        playheadFraction * (trimEndFraction - trimStartFraction);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.trimStartFraction != trimStartFraction ||
        oldDelegate.trimEndFraction != trimEndFraction ||
        oldDelegate.playheadFraction != playheadFraction ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.isPlaying != isPlaying;
  }
}
