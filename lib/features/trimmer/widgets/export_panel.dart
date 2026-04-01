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
      children: [
        // Format selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: _formats.map((format) {
              final isSelected = state.selectedFormat == format;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setSelectedFormat(format),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.bgElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.accentElec.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        format,
                        style: AppTheme.monoLabel.copyWith(
                          color: isSelected
                              ? AppTheme.accentElec
                              : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Export button or progress or success
        if (state.status == TrimmerStatus.exporting)
          _buildExportingState(state.exportProgress)
        else if (state.status == TrimmerStatus.exported)
          _buildExportedState(context, ref, state.exportedPath!)
        else if (state.status == TrimmerStatus.error &&
            state.errorMessage != null)
          _buildErrorState(context, ref, state.errorMessage!)
        else
          _buildExportButton(notifier),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 600.ms);
  }

  Widget _buildExportButton(TrimmerNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.exportTrimmed(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentElec,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentElec.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'TRIM & EXPORT',
            style: AppTheme.buttonText.copyWith(letterSpacing: 2.0),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 2000.ms,
          color: AppTheme.accentElec.withValues(alpha: 0.1),
        );
  }

  Widget _buildExportingState(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentElec.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'EXPORTING...',
            style: AppTheme.monoLabel.copyWith(
              color: AppTheme.accentElec,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bgElevated,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.accentElec),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTheme.monoValue.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExportedState(
      BuildContext context, WidgetRef ref, String path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
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
            style: AppTheme.monoLabel.copyWith(
              color: AppTheme.accentGreen,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: AppTheme.bodySmall,
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

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppTheme.accentRed, size: 32),
          const SizedBox(height: 10),
          Text(
            'EXPORT FAILED',
            style: AppTheme.monoLabel.copyWith(
              color: AppTheme.accentRed,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            error,
            style: AppTheme.bodySmall.copyWith(fontSize: 11),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.monoLabel.copyWith(
                color: color,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
