import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';

class TransportControls extends ConsumerWidget {
  const TransportControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trimmerProvider);
    final notifier = ref.read(trimmerProvider.notifier);

    if (!state.hasFile ||
        state.status == TrimmerStatus.idle ||
        state.status == TrimmerStatus.loading) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final verticalLayout = constraints.maxWidth < 520;

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: AppTheme.panelDecoration(elevated: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('TRANSPORT', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec)),
                  const Spacer(),
                  _MiniActionButton(
                    label: compact ? 'U' : 'Undo',
                    icon: Icons.undo_rounded,
                    enabled: state.canUndo,
                    onTap: notifier.undoEdit,
                  ),
                  const SizedBox(width: 6),
                  _MiniActionButton(
                    label: compact ? 'R' : 'Redo',
                    icon: Icons.redo_rounded,
                    enabled: state.canRedo,
                    onTap: notifier.redoEdit,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    label: 'Rst',
                    icon: Icons.skip_previous_rounded,
                    diameter: compact ? 46 : 52,
                    iconSize: compact ? 22 : 28,
                    onPressed: () => notifier.restart(),
                    accent: AppTheme.accentElec,
                  ),
                  _PlayPauseButton(
                    isPlaying: state.isPlaying,
                    onPressed: () => notifier.togglePlayPause(),
                    diameter: compact ? 60 : 68,
                    iconSize: compact ? 30 : 34,
                  ),
                  _ControlButton(
                    label: 'Stop',
                    icon: Icons.stop_rounded,
                    diameter: compact ? 46 : 52,
                    iconSize: compact ? 22 : 28,
                    onPressed: () async {
                      await notifier.pause();
                      notifier.seekToPosition(Duration.zero);
                    },
                    accent: AppTheme.accentRed,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (verticalLayout)
                Column(
                  children: [
                    _TogglePill(
                      label: 'Loop',
                      value: state.loopEnabled,
                      onTap: () => notifier.toggleLoop(),
                    ),
                    const SizedBox(height: 8),
                    _ZoomSlider(
                      value: state.zoomLevel,
                      onChanged: notifier.setZoomLevel,
                    ),
                    const SizedBox(height: 8),
                    _EditSettingsStrip(
                      state: state,
                      notifier: notifier,
                      vertical: true,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _TogglePill(
                        label: 'Loop trim',
                        value: state.loopEnabled,
                        onTap: () => notifier.toggleLoop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ZoomSlider(
                        value: state.zoomLevel,
                        onChanged: notifier.setZoomLevel,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (!verticalLayout)
                _EditSettingsStrip(
                  state: state,
                  notifier: notifier,
                  vertical: false,
                ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgPanel,
                  borderRadius: AppTheme.pillRadius,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      FormatUtils.formatDuration(state.currentPosition),
                      style: AppTheme.monoTimestamp,
                    ),
                    Text(' / ', style: AppTheme.monoLabel),
                    Text(
                      FormatUtils.formatDuration(state.trimmedDuration),
                      style: AppTheme.monoValue.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 260.ms, delay: 220.ms).slideY(begin: 0.06, end: 0, duration: 260.ms, delay: 220.ms);
  }
}

class _EditSettingsStrip extends StatelessWidget {
  final TrimmerState state;
  final TrimmerNotifier notifier;
  final bool vertical;

  const _EditSettingsStrip({
    required this.state,
    required this.notifier,
    required this.vertical,
  });

  static const _presets = ['BALANCED', 'MP3_LOW', 'MP3_HIGH', 'AAC_HIGH', 'WAV_MASTER'];

  @override
  Widget build(BuildContext context) {
    final presets = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _presets
          .map(
            (preset) => ChoiceChip(
              label: Text(_labelForPreset(preset)),
              selected: state.exportPreset == preset,
              onSelected: (_) => notifier.setExportPreset(preset),
            ),
          )
          .toList(),
    );

    final fadeControls = Column(
      children: [
        _TinyFadeRow(
          label: 'Fade in',
          value: state.fadeInDuration,
          maxDuration: state.trimmedDuration,
          onChanged: notifier.setFadeInDuration,
        ),
        _TinyFadeRow(
          label: 'Fade out',
          value: state.fadeOutDuration,
          maxDuration: state.trimmedDuration,
          onChanged: notifier.setFadeOutDuration,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EDIT', style: AppTheme.monoLabel),
                const SizedBox(height: 8),
                presets,
                const SizedBox(height: 8),
                fadeControls,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EDIT', style: AppTheme.monoLabel),
                      const SizedBox(height: 8),
                      presets,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: fadeControls),
              ],
            ),
    );
  }

  String _labelForPreset(String preset) {
    switch (preset) {
      case 'MP3_LOW':
        return 'MP3 96k';
      case 'MP3_HIGH':
        return 'MP3 320k';
      case 'AAC_HIGH':
        return 'AAC 256k';
      case 'WAV_MASTER':
        return 'WAV PCM';
      default:
        return 'Balanced';
    }
  }
}

class _TinyFadeRow extends StatelessWidget {
  final String label;
  final Duration value;
  final Duration maxDuration;
  final ValueChanged<Duration> onChanged;

  const _TinyFadeRow({
    required this.label,
    required this.value,
    required this.maxDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxSec = (maxDuration.inMilliseconds / 2000).clamp(0.0, 4.0);
    final current = value.inMilliseconds / 1000.0;

    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: AppTheme.monoLabel)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: current.clamp(0.0, maxSec <= 0 ? 0.5 : maxSec),
              min: 0,
              max: maxSec <= 0 ? 0.5 : maxSec,
              divisions: ((maxSec <= 0 ? 0.5 : maxSec) * 10).round().clamp(1, 40),
              onChanged: (next) => onChanged(Duration(milliseconds: (next * 1000).round())),
              activeColor: AppTheme.accentElec,
              inactiveColor: AppTheme.borderColor,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(current.toStringAsFixed(1), style: AppTheme.monoValue.copyWith(fontSize: 10)),
        ),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      toggled: value,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.pillRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: value ? AppTheme.accentElec.withValues(alpha: 0.12) : AppTheme.bgPanel,
            borderRadius: AppTheme.pillRadius,
            border: Border.all(
              color: value ? AppTheme.accentElec.withValues(alpha: 0.55) : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value ? Icons.loop_rounded : Icons.loop_outlined,
                size: 18,
                color: value ? AppTheme.accentElec : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                value ? '$label ON' : '$label OFF',
                style: AppTheme.monoLabel.copyWith(
                  color: value ? AppTheme.accentElec : AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ZoomSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.zoom_in_rounded, size: 16, color: AppTheme.accentElec),
              const SizedBox(width: 6),
              Text('ZOOM', style: AppTheme.monoLabel),
              const Spacer(),
              Text('${value.toStringAsFixed(1)}x', style: AppTheme.monoValue.copyWith(fontSize: 11)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: 1.0,
              max: 3.0,
              divisions: 4,
              onChanged: onChanged,
              activeColor: AppTheme.accentElec,
              inactiveColor: AppTheme.borderColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          textStyle: AppTheme.monoLabel.copyWith(fontSize: 10),
          side: BorderSide(color: enabled ? AppTheme.borderStrong : AppTheme.borderColor),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double diameter;
  final double iconSize;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
    required this.diameter,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pause playback' : 'Play selection',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentElec,
            foregroundColor: AppTheme.bgPrimary,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppTheme.bgPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color accent;
  final double diameter;
  final double iconSize;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accent,
    required this.diameter,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            side: BorderSide(color: accent.withValues(alpha: 0.4)),
            foregroundColor: accent,
            backgroundColor: AppTheme.bgElevated,
          ),
          child: Icon(icon, color: accent, size: iconSize),
        ),
      ),
    );
  }
}
