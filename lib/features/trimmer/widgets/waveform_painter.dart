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

    final centerY = size.height / 2;
    final maxAmplitude = size.height / 2;

    final path = Path();
    path.moveTo(0, centerY);

    final activePath = Path();
    bool activePathStarted = false;

    // Build the top half
    for (int i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final amplitude = samples[i].clamp(0.01, 1.0);
      final y = centerY - (amplitude * maxAmplitude);
      
      final fraction = i / samples.length;
      final isInTrimRegion = fraction >= trimStartFraction && fraction <= trimEndFraction;

      path.lineTo(x, y);

      if (isInTrimRegion) {
        if (!activePathStarted) {
          activePath.moveTo(x, centerY);
          activePath.lineTo(x, y);
          activePathStarted = true;
        } else {
          activePath.lineTo(x, y);
        }
      } else if (activePathStarted && fraction > trimEndFraction) {
        activePath.lineTo(x, centerY); // close off
        activePathStarted = false;
      }
    }

    path.lineTo(size.width, centerY);

    // Build the bottom half (reverse)
    for (int i = samples.length - 1; i >= 0; i--) {
      final x = (i / (samples.length - 1)) * size.width;
      final amplitude = samples[i].clamp(0.01, 1.0);
      final y = centerY + (amplitude * maxAmplitude);
      
      final fraction = i / samples.length;
      final isInTrimRegion = fraction >= trimStartFraction && fraction <= trimEndFraction;

      path.lineTo(x, y);

      if (isInTrimRegion) {
        activePath.lineTo(x, y);
      }
    }
    
    path.close();
    if (activePathStarted) {
      activePath.lineTo(trimEndFraction * size.width, centerY);
    }
    activePath.close();

    // Draw the full waveform base
    canvas.drawPath(path, Paint()..color = AppTheme.waveformBase..style = PaintingStyle.fill);

    // Darken outsides
    final overlayPaint = Paint()..color = AppTheme.bgPrimary.withValues(alpha: 0.85);
    if (trimStartFraction > 0) {
      canvas.drawRect(Rect.fromLTRB(0, 0, trimStartFraction * size.width, size.height), overlayPaint);
    }
    if (trimEndFraction < 1.0) {
      canvas.drawRect(Rect.fromLTRB(trimEndFraction * size.width, 0, size.width, size.height), overlayPaint);
    }

    // Draw the active portion in intense signal color
    canvas.drawPath(activePath, Paint()..color = AppTheme.waveformActive..style = PaintingStyle.fill);

    if (isPlaying || playheadFraction > 0) {
      final playheadX = trimStartFraction * size.width + playheadFraction * (trimEndFraction - trimStartFraction) * size.width;
      final headPaint = Paint()..color = AppTheme.textPrimary..strokeWidth = 2.0;
      canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, size.height), headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return true; 
  }
}
