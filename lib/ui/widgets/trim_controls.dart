import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../cubit/trimmer_cubit.dart';
import '../../cubit/trimmer_state.dart';
import '../../utils/time_utils.dart';

/// Trim range controls: start / end labels + editable start/end inputs +
/// [RangeSlider] + selected duration indicator.
class TrimControls extends StatefulWidget {
  const TrimControls({super.key});

  @override
  State<TrimControls> createState() => _TrimControlsState();
}

class _TrimControlsState extends State<TrimControls> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final FocusNode _startFocus;
  late final FocusNode _endFocus;
  int? _lastRangeHapticStartMs;
  int? _lastRangeHapticEndMs;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController();
    _endController = TextEditingController();
    _startFocus = FocusNode();
    _endFocus = FocusNode();

    _startFocus.addListener(() {
      if (!_startFocus.hasFocus) {
        _commitStartInput();
      }
    });
    _endFocus.addListener(() {
      if (!_endFocus.hasFocus) {
        _commitEndInput();
      }
    });
  }

  @override
  void dispose() {
    _startFocus.dispose();
    _endFocus.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _syncInputText(TrimmerState state) {
    if (!_startFocus.hasFocus) {
      final next = formatDuration(state.startDuration);
      if (_startController.text != next) {
        _startController.text = next;
      }
    }

    if (!_endFocus.hasFocus) {
      final next = formatDuration(state.endDuration);
      if (_endController.text != next) {
        _endController.text = next;
      }
    }
  }

  Duration? _tryParseTime(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final parts = text.split(':');
    if (parts.length == 1) {
      final sec = double.tryParse(parts[0]);
      if (sec == null || sec < 0) return null;
      return Duration(milliseconds: (sec * 1000).round());
    }

    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      final sec = double.tryParse(parts[1]);
      if (minutes == null || sec == null || minutes < 0 || sec < 0) return null;
      return Duration(milliseconds: ((minutes * 60 + sec) * 1000).round());
    }

    return null;
  }

  void _showInputError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Use mm:ss or mm:ss.xx (example: 01:23.45).'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _commitStartInput() {
    final parsed = _tryParseTime(_startController.text);
    if (parsed == null) {
      _showInputError();
      final state = context.read<TrimmerCubit>().state;
      _startController.text = formatDuration(state.startDuration);
      return;
    }

    context.read<TrimmerCubit>().updateStartTime(parsed);
    final state = context.read<TrimmerCubit>().state;
    _startController.text = formatDuration(state.startDuration);
  }

  void _commitEndInput() {
    final parsed = _tryParseTime(_endController.text);
    if (parsed == null) {
      _showInputError();
      final state = context.read<TrimmerCubit>().state;
      _endController.text = formatDuration(state.endDuration);
      return;
    }

    context.read<TrimmerCubit>().updateEndTime(parsed);
    final state = context.read<TrimmerCubit>().state;
    _endController.text = formatDuration(state.endDuration);
  }

  void _maybeRangeHaptic(RangeValues values) {
    final int startMs = values.start.round();
    final int endMs = values.end.round();

    final bool startMoved =
        _lastRangeHapticStartMs == null ||
        (startMs - _lastRangeHapticStartMs!).abs() >= 250;
    final bool endMoved =
        _lastRangeHapticEndMs == null ||
        (endMs - _lastRangeHapticEndMs!).abs() >= 250;

    if (startMoved || endMoved) {
      _lastRangeHapticStartMs = startMs;
      _lastRangeHapticEndMs = endMs;
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrimmerCubit, TrimmerState>(
      buildWhen: (prev, curr) =>
          prev.startDuration != curr.startDuration ||
          prev.endDuration != curr.endDuration ||
          prev.totalDuration != curr.totalDuration,
      builder: (context, state) {
        final cubit = context.read<TrimmerCubit>();
        _syncInputText(state);

        final double totalMs = state.totalDuration.inMilliseconds.toDouble();
        final double startMs = state.startDuration.inMilliseconds.toDouble();
        final double endMs = state.endDuration.inMilliseconds.toDouble();

        final bool isValid = totalMs > 0;
        final Duration selectedDuration = state.endDuration - state.startDuration;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimeLabel(
                    label: 'Start',
                    time: state.startDuration,
                    color: const Color(0xFF1DB954),
                  ),
                  _TimeLabel(
                    label: 'End',
                    time: state.endDuration,
                    color: const Color(0xFF1DB954),
                    alignRight: true,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _TimeInputField(
                      label: 'Start Time',
                      controller: _startController,
                      focusNode: _startFocus,
                      onSubmitted: (_) => _commitStartInput(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeInputField(
                      label: 'End Time',
                      controller: _endController,
                      focusNode: _endFocus,
                      onSubmitted: (_) => _commitEndInput(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF1DB954),
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: const Color(0xFF1DB954),
                  overlayColor: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                  showValueIndicator: ShowValueIndicator.onDrag,
                  valueIndicatorColor: const Color(0xFF1DB954),
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                child: RangeSlider(
                  min: 0,
                  max: isValid ? totalMs : 1.0,
                  values: isValid
                      ? RangeValues(
                          startMs.clamp(0, totalMs),
                          endMs.clamp(0, totalMs),
                        )
                      : const RangeValues(0, 1),
                  labels: RangeLabels(
                    formatDuration(state.startDuration),
                    formatDuration(state.endDuration),
                  ),
                  activeColor: const Color(0xFF1DB954),
                  inactiveColor: Colors.grey.shade800,
                  onChangeStart: isValid
                      ? (_) {
                          _lastRangeHapticStartMs = null;
                          _lastRangeHapticEndMs = null;
                          HapticFeedback.lightImpact();
                        }
                      : null,
                  onChanged: isValid
                      ? (RangeValues values) {
                          _maybeRangeHaptic(values);
                          cubit.updateStartTime(
                            Duration(milliseconds: values.start.round()),
                          );
                          cubit.updateEndTime(
                            Duration(milliseconds: values.end.round()),
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

              Center(
                child: Text(
                  'Duration: ${formatDuration(selectedDuration.isNegative ? Duration.zero : selectedDuration)}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Private helper ────────────────────────────────────────────────────────────

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.label,
    required this.time,
    required this.color,
    this.alignRight = false,
  });

  final String label;
  final Duration time;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatDuration(time),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TimeInputField extends StatelessWidget {
  const _TimeInputField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(
        color: Color(0xFF1DB954),
        fontWeight: FontWeight.w700,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'mm:ss.xx',
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1DB954), width: 1.2),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
