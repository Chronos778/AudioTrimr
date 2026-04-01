import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';
import '../widgets/file_import_zone.dart';
import '../widgets/waveform_painter.dart';
import '../widgets/trim_handle.dart';
import '../widgets/playback_controls.dart';
import '../widgets/trim_info_bar.dart';
import '../widgets/export_panel.dart';

class TrimmerScreen extends ConsumerStatefulWidget {
  const TrimmerScreen({super.key});

  @override
  ConsumerState<TrimmerScreen> createState() => _TrimmerScreenState();
}

class _TrimmerScreenState extends ConsumerState<TrimmerScreen> {
  final GlobalKey _waveformKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trimmerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── TOP BAR ─────────────────────────────────
                _buildTopBar(),
                const SizedBox(height: 16),

                // ─── FILE INFO OR IMPORT ─────────────────────
                if (state.hasFile && state.status != TrimmerStatus.idle)
                  _buildFileInfoBar(state)
                else
                  const FileImportZone(),

                const SizedBox(height: 16),

                // ─── WAVEFORM VISUALIZER ─────────────────────
                if (state.hasFile && state.waveform != null)
                  _buildWaveformSection(state),

                if (state.hasFile && state.waveform != null)
                  const SizedBox(height: 12),

                // ─── TRIM INFO BAR ───────────────────────────
                const TrimInfoBar(),

                if (state.hasFile) const SizedBox(height: 12),

                // ─── PLAYBACK CONTROLS ───────────────────────
                const PlaybackControls(),

                if (state.hasFile) const SizedBox(height: 12),

                // ─── EXPORT ──────────────────────────────────
                const ExportPanel(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Text(
          'TRIMR',
          style: AppTheme.monoDisplay.copyWith(
            color: AppTheme.accentElec,
            fontSize: 24,
            letterSpacing: 3.0,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            'v1.0',
            style: AppTheme.monoLabel.copyWith(fontSize: 9),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms);
  }

  Widget _buildFileInfoBar(TrimmerState state) {
    final meta = state.metadata!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filename row with re-import button
          Row(
            children: [
              Icon(Icons.audio_file_outlined,
                  color: AppTheme.accentElec, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.fileName,
                  style: AppTheme.monoValue.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(trimmerProvider.notifier).resetForNewFile(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    'CHANGE',
                    style: AppTheme.monoLabel.copyWith(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Metadata row
          Row(
            children: [
              _MetaChip(label: 'FORMAT', value: meta.format),
              const SizedBox(width: 16),
              _MetaChip(
                label: 'DURATION',
                value: FormatUtils.formatDurationLong(meta.duration),
              ),
              const SizedBox(width: 16),
              _MetaChip(
                label: 'SIZE',
                value: FormatUtils.formatFileSize(meta.fileSize),
              ),
              if (meta.bitrate > 0) ...[
                const SizedBox(width: 16),
                _MetaChip(
                  label: 'BITRATE',
                  value: FormatUtils.formatBitrate(meta.bitrate),
                ),
              ],
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 200.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms, delay: 200.ms);
  }

  Widget _buildWaveformSection(TrimmerState state) {
    final totalDuration = state.metadata?.duration ?? Duration.zero;
    final totalMs = totalDuration.inMilliseconds.toDouble();

    final trimStartFraction =
        totalMs > 0 ? state.trimStart.inMilliseconds / totalMs : 0.0;
    final trimEndFraction =
        totalMs > 0 ? state.trimEnd.inMilliseconds / totalMs : 1.0;

    // Calculate playhead as fraction within trim region
    final trimDurationMs = state.trimmedDuration.inMilliseconds.toDouble();
    final playheadFraction = trimDurationMs > 0
        ? (state.currentPosition.inMilliseconds / trimDurationMs).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // Waveform with handles
        LayoutBuilder(
          builder: (context, constraints) {
            final waveformWidth = constraints.maxWidth;
            const waveformHeight = 160.0;

            return Container(
              key: _waveformKey,
              height: waveformHeight,
              width: waveformWidth,
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  children: [
                    // Waveform
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CustomPaint(
                          painter: WaveformPainter(
                            samples: state.waveform!.samples,
                            trimStartFraction: trimStartFraction,
                            trimEndFraction: trimEndFraction,
                            playheadFraction: playheadFraction,
                            isPlaying: state.isPlaying,
                          ),
                        ),
                      ),
                    ),

                    // Tap to seek
                    Positioned.fill(
                      child: GestureDetector(
                        onTapDown: (details) {
                          final fraction =
                              details.localPosition.dx / waveformWidth;
                          final position = Duration(
                            milliseconds:
                                (fraction * totalMs).round(),
                          );
                          // Only seek within trim region
                          if (position >= state.trimStart &&
                              position <= state.trimEnd) {
                            final relativePos = position - state.trimStart;
                            ref
                                .read(trimmerProvider.notifier)
                                .seekToPosition(relativePos);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),

                    // Start handle
                    TrimHandle(
                      type: HandleType.start,
                      position: trimStartFraction,
                      containerWidth: waveformWidth,
                      containerHeight: waveformHeight,
                      onDrag: (newPos) {
                        final newTime = Duration(
                          milliseconds: (newPos * totalMs).round(),
                        );
                        ref
                            .read(trimmerProvider.notifier)
                            .setTrimStart(newTime);
                      },
                    ),

                    // End handle
                    TrimHandle(
                      type: HandleType.end,
                      position: trimEndFraction,
                      containerWidth: waveformWidth,
                      containerHeight: waveformHeight,
                      onDrag: (newPos) {
                        final newTime = Duration(
                          milliseconds: (newPos * totalMs).round(),
                        );
                        ref
                            .read(trimmerProvider.notifier)
                            .setTrimEnd(newTime);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 6),

        // Timestamp labels below handles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FormatUtils.formatDuration(state.trimStart),
                style: AppTheme.monoTimestamp.copyWith(
                  color: AppTheme.accentGreen,
                  fontSize: 11,
                ),
              ),
              Text(
                FormatUtils.formatDuration(state.trimEnd),
                style: AppTheme.monoTimestamp.copyWith(
                  color: AppTheme.accentRed,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 300.ms);
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.monoLabel.copyWith(fontSize: 8, letterSpacing: 1.2),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.monoValue.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
