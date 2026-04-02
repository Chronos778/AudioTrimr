import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme.dart';
import '../providers/trimmer_provider.dart';

class ExportPanel extends ConsumerWidget {
  const ExportPanel({super.key});

  static const _formats = ['MP3', 'WAV', 'AAC', 'M4A'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trimmerProvider);
    final notifier = ref.read(trimmerProvider.notifier);

    if (!state.hasFile ||
        state.status == TrimmerStatus.idle ||
        state.status == TrimmerStatus.loading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FORMAT', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: _formats
              .map(
                (format) => ButtonSegment<String>(
                  value: format,
                  label: Text(format),
                  icon: const Icon(Icons.audio_file_outlined, size: 18),
                ),
              )
              .toList(),
          selected: {state.selectedFormat},
          onSelectionChanged: (selection) {
            notifier.setSelectedFormat(selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (state.status == TrimmerStatus.exporting)
          _buildExportingState(state.exportProgress)
        else if (state.status == TrimmerStatus.exported &&
            state.exportedPath != null)
          _buildExportedState(context, ref, state.exportedPath!)
        else if (state.status == TrimmerStatus.error &&
            state.errorMessage != null)
          _buildErrorState(context, ref, state.errorMessage!)
        else
          _buildExportButton(notifier),
      ],
    )
        .animate()
        .fadeIn(duration: 260.ms, delay: 220.ms)
        .slideY(begin: 0.08, end: 0, duration: 260.ms, delay: 220.ms);
  }

  Widget _buildExportButton(TrimmerNotifier notifier) {
    return Semantics(
      button: true,
      label: 'Trim and export',
      hint: 'Creates the selected output file in the chosen format',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => notifier.exportTrimmed(),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentElec,
            foregroundColor: AppTheme.bgPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const StadiumBorder(),
          ),
          child: const Text('TRIM & EXPORT'),
        ),
      ),
    );
  }

  Widget _buildExportingState(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: AppTheme.accentElec.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPORTING',
            style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentElec),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTheme.monoValue.copyWith(
              fontSize: 12,
              color: AppTheme.accentInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportedState(BuildContext context, WidgetRef ref, String path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successTint,
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.accentGreen,
            size: 36,
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 10),
          Text(
            'EXPORT COMPLETE',
            style: AppTheme.monoLabel.copyWith(color: AppTheme.accentGreen),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'SHARE',
                  icon: Icons.share_outlined,
                  color: AppTheme.accentElec,
                  onTap: () {
                    Share.shareXFiles([XFile(path)]);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'TRIM ANOTHER',
                  icon: Icons.restart_alt_rounded,
                  color: AppTheme.textMuted,
                  onTap: () {
                    ref.read(trimmerProvider.notifier).resetForNewFile();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorTint,
        borderRadius: AppTheme.panelRadius,
        border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppTheme.accentRed, size: 32),
          const SizedBox(height: 10),
          Text(
            'EXPORT FAILED',
            style: AppTheme.monoLabel.copyWith(color: AppTheme.accentRed),
          ),
          const SizedBox(height: 8),
          SelectableText(
            error,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'RETRY',
            icon: Icons.refresh_rounded,
            color: AppTheme.accentElec,
            onTap: () => ref.read(trimmerProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}
