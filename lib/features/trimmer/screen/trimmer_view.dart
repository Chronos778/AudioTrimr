import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';
import '../widgets/export_panel.dart';
import '../widgets/file_import_zone.dart';
import '../widgets/transport_controls.dart';
import '../widgets/trim_handle.dart';
import '../widgets/trim_info_bar.dart';
import '../widgets/waveform_painter.dart';

class TrimmerView extends ConsumerStatefulWidget {
  const TrimmerView({super.key});

  @override
  ConsumerState<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends ConsumerState<TrimmerView> {
  final GlobalKey _waveformKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trimmerProvider);
    final hasFile = state.hasFile;
    final showEditor = hasFile && state.status != TrimmerStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            const _Backdrop(),
            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 1120;
                final showTimeline = showEditor;
                final showInspector = hasFile;

                final leftDock = _buildMediaDock(state);
                final centerDeck = showTimeline ? _buildTimelineDeck(state, showEditor) : null;
                final rightDock = showInspector ? _buildInspectorDock(state) : null;

                if (!desktop) {
                  return _buildMobileWorkspace(
                    state: state,
                    topBar: _buildTopBar(state, compact: true),
                    mediaDock: leftDock,
                    timelineDeck: centerDeck,
                    inspectorDock: rightDock,
                    showTimeline: showTimeline,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: Column(
                        children: [
                            _buildTopBar(state, compact: false)
                              .animate()
                              .fadeIn(duration: 260.ms)
                              .slideY(begin: -0.06, end: 0, duration: 280.ms),
                          const SizedBox(height: 12),
                          Expanded(
                            child: showTimeline
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 300, child: leftDock),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (state.errorMessage != null &&
                                                state.status == TrimmerStatus.error) ...[
                                              _StatusBanner(
                                                title: 'FAILED',
                                                message: state.errorMessage!,
                                                icon: Icons.error_outline_rounded,
                                                tone: AppTheme.accentRed,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                            Expanded(child: centerDeck!),
                                          ],
                                        ),
                                      ),
                                      if (rightDock != null) ...[
                                        const SizedBox(width: 12),
                                        SizedBox(width: 330, child: rightDock),
                                      ],
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.topLeft,
                                    child: SizedBox(width: 360, child: leftDock),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileWorkspace({
    required TrimmerState state,
    required Widget topBar,
    required Widget mediaDock,
    Widget? timelineDeck,
    Widget? inspectorDock,
    required bool showTimeline,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            const SizedBox(height: 10),
            if (state.errorMessage != null && state.status == TrimmerStatus.error) ...[
              _StatusBanner(
                title: 'FAILED',
                message: state.errorMessage!,
                icon: Icons.error_outline_rounded,
                tone: AppTheme.accentRed,
              ),
              const SizedBox(height: 10),
            ],
            mediaDock,
            if (showTimeline && timelineDeck != null) ...[
              const SizedBox(height: 10),
              timelineDeck,
            ],
            if (showTimeline && inspectorDock != null) ...[
              const SizedBox(height: 10),
              inspectorDock,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(TrimmerState state, {required bool compact}) {
    final meta = state.metadata;

    return _DockPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: compact ? _buildCompactTopBar(state, meta) : _buildWideTopBar(state, meta),
    );
  }

  Widget _buildCompactTopBar(TrimmerState state, dynamic meta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TRIMR',
              style: AppTheme.monoDisplay.copyWith(fontSize: 22, letterSpacing: 0.8),
            ),
            const Spacer(),
            _StateDot(status: state.status, compact: true),
          ],
        ),
        const SizedBox(height: 10),
        if (meta != null) ...[
          Text(
            meta.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.titleText.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(label: 'DUR', value: FormatUtils.formatDurationLong(meta.duration)),
              _HeaderPill(label: 'FMT', value: meta.format.toUpperCase()),
              if (meta.bitrate > 0)
                _HeaderPill(label: 'BIT', value: FormatUtils.formatBitrate(meta.bitrate)),
            ],
          ),
        ] else
          Text(
            'Ready',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
          ),
      ],
    );
  }

  Widget _buildWideTopBar(TrimmerState state, dynamic meta) {
    return Row(
      children: [
        Text(
          'TRIMR',
          style: AppTheme.monoDisplay.copyWith(fontSize: 28, letterSpacing: 0.8),
        ),
        const SizedBox(width: 14),
        if (meta != null)
          Expanded(
            child: Row(
              children: [
                Flexible(
                  flex: 4,
                  child: Text(
                    meta.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleText.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderPill(label: 'DUR', value: FormatUtils.formatDurationLong(meta.duration)),
                const SizedBox(width: 8),
                _HeaderPill(label: 'FMT', value: meta.format.toUpperCase()),
                if (meta.bitrate > 0) ...[
                  const SizedBox(width: 8),
                  _HeaderPill(label: 'BIT', value: FormatUtils.formatBitrate(meta.bitrate)),
                ],
              ],
            ),
          )
        else
          Expanded(
            child: Text(
              'Ready',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textMuted),
            ),
          ),
        const SizedBox(width: 10),
        _StateDot(status: state.status),
      ],
    );
  }

  Widget _buildMediaDock(TrimmerState state) {
    final meta = state.metadata;

    return _DockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDockHeader(
            title: 'MEDIA',
            subtitle: 'Source',
            icon: Icons.perm_media_rounded,
          ),
          const SizedBox(height: 12),
          if (meta == null) ...[
            const FileImportZone(),
            const SizedBox(height: 12),
            const _MutedNote(
              text: 'Import audio.',
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgPanel,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleText.copyWith(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.read(trimmerProvider.notifier).resetForNewFile(),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Replace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CompactRow(label: 'Size', value: FormatUtils.formatFileSize(meta.fileSize)),
                  _CompactRow(label: 'Format', value: meta.format),
                  _CompactRow(
                    label: 'Duration',
                    value: FormatUtils.formatDurationLong(meta.duration),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 10),
          Text('QUEUE', style: AppTheme.monoLabel),
          const SizedBox(height: 8),
          _QueueStrip(state: state),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideX(begin: -0.03, end: 0, duration: 280.ms);
  }

  Widget _buildTimelineDeck(TrimmerState state, bool showEditor) {
    if (!showEditor) {
      return _DockPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _DockHeaderMini(
              title: 'TIMELINE',
              subtitle: 'Load source',
            ),
            SizedBox(height: 14),
            _LockedPanel(
              title: 'No source',
              message: 'Import audio to edit.',
            ),
          ],
        ),
      ).animate().fadeIn(duration: 260.ms);
    }

    return _DockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DockHeaderMini(
            title: 'TIMELINE',
            subtitle: 'In/Out',
          ),
          const SizedBox(height: 12),
          _buildFileInfoBar(state),
          const SizedBox(height: 12),
          state.waveform != null ? _buildWaveformSection(state) : _buildWaveformPlaceholder(),
          const SizedBox(height: 12),
          const TrimInfoBar(),
          const SizedBox(height: 10),
          const TransportControls(),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.03, end: 0, duration: 280.ms);
  }

  Widget _buildInspectorDock(TrimmerState state) {
    final hasFile = state.hasFile;

    return _DockPanel(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDockHeader(
              title: 'INSPECTOR',
              subtitle: 'Edit + export',
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 12),
            Text('SELECTION', style: AppTheme.monoLabel),
            const SizedBox(height: 8),
            _SelectionBlock(state: state),
            const SizedBox(height: 12),
            Text('DELIVER', style: AppTheme.monoLabel),
            const SizedBox(height: 8),
            if (hasFile)
              const ExportPanel()
            else
              const _LockedPanel(
                title: 'Export unavailable',
                message: 'Load source first.',
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideX(begin: 0.03, end: 0, duration: 280.ms);
  }

  Widget _buildDockHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.accentElec),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.monoLabel),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileInfoBar(TrimmerState state) {
    final meta = state.metadata!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              meta.fileName,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.titleText.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => ref.read(trimmerProvider.notifier).resetForNewFile(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformSection(TrimmerState state) {
    final totalDuration = state.metadata?.duration ?? Duration.zero;
    final totalMs = totalDuration.inMilliseconds.toDouble();

    final trimStartFraction = totalMs > 0 ? state.trimStart.inMilliseconds / totalMs : 0.0;
    final trimEndFraction = totalMs > 0 ? state.trimEnd.inMilliseconds / totalMs : 1.0;

    final trimDurationMs = state.trimmedDuration.inMilliseconds.toDouble();
    final playheadFraction =
        trimDurationMs > 0 ? (state.currentPosition.inMilliseconds / trimDurationMs).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final waveformWidth = constraints.maxWidth;
            const waveformHeight = 188.0;

            return Container(
              key: _waveformKey,
              height: waveformHeight,
              width: waveformWidth,
              decoration: BoxDecoration(
                color: AppTheme.bgPanel,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderStrong),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: CustomPaint(
                          painter: WaveformPainter(
                            samples: state.waveform!.samples,
                            trimStartFraction: trimStartFraction,
                            trimEndFraction: trimEndFraction,
                            playheadFraction: playheadFraction,
                            zoomLevel: state.zoomLevel,
                            isPlaying: state.isPlaying,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTapDown: (details) {
                          final fraction = details.localPosition.dx / waveformWidth;
                          final position = Duration(milliseconds: (fraction * totalMs).round());
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
                      onNudge: (deltaFraction) {
                        final newFraction = (trimStartFraction + deltaFraction).clamp(0.0, 1.0);
                        final newTime = Duration(milliseconds: (newFraction * totalMs).round());
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
                      onNudge: (deltaFraction) {
                        final newFraction = (trimEndFraction + deltaFraction).clamp(0.0, 1.0);
                        final newTime = Duration(milliseconds: (newFraction * totalMs).round());
                        ref.read(trimmerProvider.notifier).setTrimEnd(newTime);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'In  ${FormatUtils.formatDuration(state.trimStart)}',
              style: AppTheme.monoTimestamp.copyWith(color: AppTheme.accentGreen),
            ),
            Text(
              'Out  ${FormatUtils.formatDuration(state.trimEnd)}',
              style: AppTheme.monoTimestamp.copyWith(color: AppTheme.accentRed),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformPlaceholder() {
    return Container(
      height: 188,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ANALYZING', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec)),
          const SizedBox(height: 8),
          Text('Waveform extraction in progress.', style: AppTheme.bodySmall),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            minHeight: 5,
            backgroundColor: AppTheme.bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentElec),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: AppTheme.ambientBackdropDecoration()),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(
              diameter: 320,
              color: AppTheme.accentElec.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -90,
            child: _GlowBlob(
              diameter: 360,
              color: AppTheme.accentGreen.withValues(alpha: 0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _BackdropGridPainter(color: AppTheme.borderColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double diameter;
  final Color color;

  const _GlowBlob({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _BackdropGridPainter extends CustomPainter {
  final Color color;

  _BackdropGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DockPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DockPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.panelDecoration(elevated: true),
      child: child,
    );
  }
}

class _DockHeaderMini extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DockHeaderMini({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.monoLabel),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTheme.bodySmall),
      ],
    );
  }
}

class _StateDot extends StatelessWidget {
  final TrimmerStatus status;
  final bool compact;

  const _StateDot({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isBusy = status == TrimmerStatus.loading || status == TrimmerStatus.exporting;
    final isError = status == TrimmerStatus.error;
    final isDone = status == TrimmerStatus.exported;

    final tone = isError
        ? AppTheme.accentRed
        : isBusy
            ? AppTheme.accentElec
            : isDone
                ? AppTheme.accentGreen
                : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: AppTheme.pillRadius,
        color: tone.withValues(alpha: 0.14),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
          ),
          const SizedBox(width: 8),
          Text(
            compact ? _compactLabel() : status.name.toUpperCase(),
            style: AppTheme.monoLabel.copyWith(color: tone),
          ),
        ],
      ),
    );
  }

  String _compactLabel() {
    switch (status) {
      case TrimmerStatus.idle:
        return 'READY';
      case TrimmerStatus.loaded:
        return 'READY';
      case TrimmerStatus.loading:
        return 'LOADING';
      case TrimmerStatus.playing:
        return 'PLAYING';
      case TrimmerStatus.exporting:
        return 'RENDERING';
      case TrimmerStatus.exported:
        return 'DONE';
      case TrimmerStatus.error:
        return 'ERROR';
      default:
        return status.name.toUpperCase();
    }
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.bgPanel,
      ),
      child: RichText(
        text: TextSpan(
          style: AppTheme.monoValue.copyWith(fontSize: 10, color: AppTheme.textPrimary),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: AppTheme.monoValue.copyWith(
                fontSize: 10,
                color: AppTheme.accentElec,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 74, child: Text(label.toUpperCase(), style: AppTheme.monoLabel)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueStrip extends StatelessWidget {
  final TrimmerState state;

  const _QueueStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == TrimmerStatus.exporting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactRow(label: 'Job', value: 'Render active'),
          LinearProgressIndicator(
            value: state.exportProgress,
            minHeight: 5,
            backgroundColor: AppTheme.bgElevated,
          ),
        ],
      );
    }

    if (state.status == TrimmerStatus.exported && state.exportedPath != null) {
      final output = state.exportedPath!.split('\\').last.split('/').last;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CompactRow(label: 'Job', value: 'Render complete'),
          _CompactRow(label: 'Output', value: output),
        ],
      );
    }

    return const _MutedNote(text: 'No active render jobs.');
  }
}

class _SelectionBlock extends StatelessWidget {
  final TrimmerState state;

  const _SelectionBlock({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.hasFile) {
      return const _MutedNote(text: 'Selection metrics appear after source load.');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactRow(label: 'In', value: FormatUtils.formatDuration(state.trimStart)),
          _CompactRow(label: 'Out', value: FormatUtils.formatDuration(state.trimEnd)),
          _CompactRow(label: 'Span', value: FormatUtils.formatDuration(state.trimmedDuration)),
          _CompactRow(label: 'Playhead', value: FormatUtils.formatDuration(state.currentPosition)),
        ],
      ),
    );
  }
}

class _MutedNote extends StatelessWidget {
  final String text;

  const _MutedNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted));
  }
}

class _LockedPanel extends StatelessWidget {
  final String title;
  final String message;

  const _LockedPanel({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.titleText.copyWith(fontSize: 15)),
          const SizedBox(height: 6),
          Text(message, style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color tone;

  const _StatusBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: tone.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.monoLabel.copyWith(color: tone)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
