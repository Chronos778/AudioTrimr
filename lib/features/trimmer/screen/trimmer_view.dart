import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';
import '../widgets/export_panel.dart';
import '../widgets/file_import_zone.dart';
import '../widgets/transport_controls.dart';
import '../widgets/trim_info_bar.dart';
import '../widgets/trim_handle.dart';
import '../widgets/waveform_painter.dart';

class TrimmerView extends ConsumerStatefulWidget {
  const TrimmerView({super.key});

  @override
  ConsumerState<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends ConsumerState<TrimmerView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trimmerProvider);
    final hasFile = state.hasFile;
    final loading = state.status == TrimmerStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppTheme.standardDuration,
          switchInCurve: AppTheme.easeOutSmooth,
          switchOutCurve: AppTheme.easeOutSmooth,
          child: (!hasFile || loading)
              ? _buildEntryState(loading)
              : _buildEditorState(state),
        ),
      ),
    );
  }

  Widget _buildEntryState(bool loading) {
    return Padding(
      key: const ValueKey('entry'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderBrand(),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: loading
                    ? _buildLoadingState()
                    : const FileImportZone().animate().fadeIn(
                          duration: AppTheme.expressiveDuration,
                          curve: AppTheme.easeOutSmooth,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorState(TrimmerState state) {
    return LayoutBuilder(
      key: const ValueKey('editor'),
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderBar(trimmedDuration: state.trimmedDuration),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: AppTheme.panelDecoration(elevated: true),
                  padding: const EdgeInsets.all(12),
                  child: _buildInteractiveCanvas(state),
                ),
              ),
              const SizedBox(height: 12),
              const TrimInfoBar(),
              const SizedBox(height: 12),
              if (compact)
                const Column(
                  children: [
                    TransportControls(),
                    SizedBox(height: 12),
                    ExportPanel(),
                  ],
                )
              else
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: TransportControls()),
                    SizedBox(width: 12),
                    SizedBox(width: 340, child: ExportPanel()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: AppTheme.panelDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'IMPORTING AUDIO',
            style: AppTheme.monoLabel.copyWith(color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCanvas(TrimmerState state) {
    final totalDuration = state.metadata?.duration ?? Duration.zero;
    final totalMs = totalDuration.inMilliseconds.toDouble();

    final trimStartFraction = totalMs > 0 ? state.trimStart.inMilliseconds / totalMs : 0.0;
    final trimEndFraction = totalMs > 0 ? state.trimEnd.inMilliseconds / totalMs : 1.0;

    final trimDurationMs = state.trimmedDuration.inMilliseconds.toDouble();
    final playheadFraction =
        trimDurationMs > 0 ? (state.currentPosition.inMilliseconds / trimDurationMs).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final waveformWidth = constraints.maxWidth;
        final waveformHeight = constraints.maxHeight;

        return ClipRRect(
          borderRadius: AppTheme.panelRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: WaveformPainter(
                    samples: state.waveform?.samples ?? [],
                    trimStartFraction: trimStartFraction,
                    trimEndFraction: trimEndFraction,
                    playheadFraction: playheadFraction,
                    zoomLevel: state.zoomLevel,
                    isPlaying: state.isPlaying,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    final fraction = details.localPosition.dx / waveformWidth;
                    final position = Duration(
                      milliseconds: (fraction * totalMs).round(),
                    );
                    if (position >= state.trimStart && position <= state.trimEnd) {
                      final relativePos = position - state.trimStart;
                      ref.read(trimmerProvider.notifier).seekToPosition(relativePos);
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              TrimHandle(
                type: HandleType.start,
                position: trimStartFraction,
                containerWidth: waveformWidth,
                containerHeight: waveformHeight,
                nudgeFraction: 0.01,
                onDrag: (newPos) {
                  final newTime = Duration(milliseconds: (newPos * totalMs).round());
                  ref.read(trimmerProvider.notifier).setTrimStart(newTime);
                },
              ),
              TrimHandle(
                type: HandleType.end,
                position: trimEndFraction,
                containerWidth: waveformWidth,
                containerHeight: waveformHeight,
                nudgeFraction: 0.01,
                onDrag: (newPos) {
                  final newTime = Duration(milliseconds: (newPos * totalMs).round());
                  ref.read(trimmerProvider.notifier).setTrimEnd(newTime);
                },
              ),
            ],
          ),
        ).animate().fadeIn(
              duration: AppTheme.standardDuration,
              curve: AppTheme.easeOutSmooth,
            );
      },
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRIMR',
          style: AppTheme.monoDisplay.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text('AUDIO TRIMMER', style: AppTheme.monoLabel),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final Duration trimmedDuration;

  const _HeaderBar({required this.trimmedDuration});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Expanded(child: _HeaderBrand()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('DURATION', style: AppTheme.monoLabel),
              const SizedBox(height: 6),
              Text(
                FormatUtils.formatDurationLong(trimmedDuration),
                style: AppTheme.monoValue.copyWith(
                  fontSize: 20,
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
