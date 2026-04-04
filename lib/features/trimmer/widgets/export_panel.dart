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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('FORMAT', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentBlue)),
              const Spacer(),
              for (var format in _formats) ...[
                GestureDetector(
                  onTap: () => notifier.setSelectedFormat(format),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.selectedFormat == format ? AppTheme.accentBlue : AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: state.selectedFormat == format ? AppTheme.accentBlue : AppTheme.borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      format,
                      style: AppTheme.monoValue.copyWith(
                        color: state.selectedFormat == format ? AppTheme.bgPrimary : AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (format != _formats.last) const SizedBox(width: 8),
              ]
            ],
          ),
          const SizedBox(height: 16),
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
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400), curve: AppTheme.easeOutSmooth);
  }

  Widget _buildExportButton(TrimmerNotifier notifier) {
    return Semantics(
      button: true,
      label: 'Trim and export',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => notifier.exportTrimmed(),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: AppTheme.bgPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
          child: const Text('EXPORT'),
        ),
      ),
    );
  }

  Widget _buildExportingState(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RENDERING', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentBlue)),
            Text('${(progress * 100).toInt()}%', style: AppTheme.monoValue.copyWith(color: AppTheme.accentBlue, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              width: constraints.maxWidth * progress,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportedState(BuildContext context, WidgetRef ref, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STATUS: SUCCESS', style: AppTheme.monoLabel.copyWith(color: AppTheme.successTint)),
            const Spacer(),
            Text(path.split('/').last, style: AppTheme.monoValue.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'SHARE',
                color: AppTheme.accentBlue,
                onTap: () {
                  Share.shareXFiles([XFile(path)]);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'NEW',
                color: AppTheme.textMuted,
                onTap: () {
                  ref.read(trimmerProvider.notifier).resetForNewFile();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS: ERROR', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentRed)),
        const SizedBox(height: 8),
        Text(error, style: AppTheme.monoValue.copyWith(fontSize: 10, color: AppTheme.accentRed)),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'RETRY',
          color: AppTheme.accentRed,
          onTap: () => ref.read(trimmerProvider.notifier).clearError(),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            side: BorderSide(color: color, width: 1.0),
          ),
          child: Text(
            label,
            style: AppTheme.monoValue.copyWith(fontSize: 12, color: color),
          ),
        ),
      ),
    );
  }
}
