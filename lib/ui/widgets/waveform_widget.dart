import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// Displays the audio waveform for a loaded file using [audio_waveforms].
///
/// The parent is responsible for:
/// - Creating and disposing the [PlayerController].
/// - Calling [PlayerController.preparePlayer] before this widget is shown.
///
/// This widget does not own the controller lifecycle.
class WaveformWidget extends StatefulWidget {
  const WaveformWidget({
    super.key,
    required this.playerController,
  });

  /// The [PlayerController] that has already been prepared with the audio file.
  final PlayerController playerController;

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AudioFileWaveforms(
        size: Size(MediaQuery.of(context).size.width, 120),
        playerController: widget.playerController,
        waveformType: WaveformType.long,
        enableSeekGesture: true,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        playerWaveStyle: PlayerWaveStyle(
          // Unplayed region — dim grey
          fixedWaveColor: Colors.grey.shade700,
          // Played / selected region — Spotify-green
          liveWaveColor: const Color(0xFF1DB954),
          // Seek / playhead indicator line
          seekLineColor: const Color(0xFF1DB954),
          seekLineThickness: 2.0,
          waveThickness: 3.0,
          spacing: 4,
          showSeekLine: true,
          waveCap: StrokeCap.round,
          scaleFactor: 20.0,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
