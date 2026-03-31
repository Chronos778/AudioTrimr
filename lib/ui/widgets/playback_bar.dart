import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../cubit/trimmer_cubit.dart';
import '../../cubit/trimmer_state.dart';
import '../../utils/time_utils.dart';

/// Playback seek bar and position indicator.
///
/// Displays the current playhead position as a [Slider] whose range is
/// constrained to [TrimmerState.startDuration] → [TrimmerState.endDuration].
///
/// [onSeek] is called when the user drags the slider; the parent screen
/// is responsible for forwarding this to the audio player.
class PlaybackBar extends StatefulWidget {
  const PlaybackBar({
    super.key,
    required this.onSeek,
    required this.audioPlayer,
    required this.isPlaying,
  });

  /// Called with the desired [Duration] when the user seeks.
  final void Function(Duration position) onSeek;
  final ja.AudioPlayer audioPlayer;
  final bool isPlaying;

  @override
  State<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<PlaybackBar> {
  int? _lastSeekHapticMs;

  void _maybeSeekHaptic(double value) {
    final int valueMs = value.round();
    if (_lastSeekHapticMs == null ||
        (valueMs - _lastSeekHapticMs!).abs() >= 250) {
      _lastSeekHapticMs = valueMs;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrimmerCubit, TrimmerState>(
      buildWhen: (prev, curr) =>
          prev.playheadPosition != curr.playheadPosition ||
          prev.startDuration != curr.startDuration ||
          prev.endDuration != curr.endDuration,
      builder: (context, state) {
        final double startMs = state.startDuration.inMilliseconds.toDouble();
        final double endMs = state.endDuration.inMilliseconds.toDouble();
        final bool isValid = endMs > startMs;
        final Duration selectedDuration = state.endDuration - state.startDuration;

        return StreamBuilder<Duration>(
          stream: widget.audioPlayer.positionStream,
          initialData: state.playheadPosition,
          builder: (context, snap) {
            final streamPos = snap.data ?? Duration.zero;
            final rawPos = widget.isPlaying &&
                    streamPos > state.playheadPosition
                ? streamPos
                : state.playheadPosition;
            final clampedPos = rawPos < state.startDuration
                ? state.startDuration
                : (rawPos > state.endDuration ? state.endDuration : rawPos);
            final double posMs = clampedPos.inMilliseconds
                .toDouble()
                .clamp(startMs, endMs);

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF1DB954),
                      inactiveTrackColor: Colors.grey.shade800,
                      thumbColor: Colors.white,
                      overlayColor:
                          const Color(0xFF1DB954).withValues(alpha: 0.12),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 3,
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      min: isValid ? startMs : 0,
                      max: isValid ? endMs : 1,
                      value: isValid ? posMs : 0,
                      activeColor: const Color(0xFF1DB954),
                      onChangeStart: isValid
                          ? (_) {
                              _lastSeekHapticMs = null;
                              HapticFeedback.lightImpact();
                            }
                          : null,
                      onChanged: isValid
                          ? (double value) {
                              _maybeSeekHaptic(value);
                              widget.onSeek(
                                Duration(milliseconds: value.round()),
                              );
                            }
                          : null,
                      onChangeEnd: isValid
                          ? (_) {
                              HapticFeedback.lightImpact();
                            }
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(clampedPos - state.startDuration <
                                  Duration.zero
                              ? Duration.zero
                              : clampedPos - state.startDuration),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          formatDuration(selectedDuration.isNegative
                              ? Duration.zero
                              : selectedDuration),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
