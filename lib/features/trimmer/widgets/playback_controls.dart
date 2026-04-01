import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';

class PlaybackControls extends ConsumerWidget {
  const PlaybackControls({super.key});

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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Restart button
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                onPressed: () => notifier.restart(),
                size: 28,
              ),
              const SizedBox(width: 24),
              // Play/Pause button
              _PlayPauseButton(
                isPlaying: state.isPlaying,
                onPressed: () => notifier.togglePlayPause(),
              ),
              const SizedBox(width: 24),
              // Stop button
              _ControlButton(
                icon: Icons.stop_rounded,
                onPressed: () async {
                  await notifier.pause();
                  notifier.seekToPosition(Duration.zero);
                },
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Position / Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FormatUtils.formatDuration(state.currentPosition),
                style: AppTheme.monoTimestamp,
              ),
              Text(
                ' / ',
                style: AppTheme.monoLabel,
              ),
              Text(
                FormatUtils.formatDuration(state.trimmedDuration),
                style: AppTheme.monoValue.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 500.ms);
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentElec,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentElec.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: AppTheme.bgPrimary,
          size: 32,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.bgElevated,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: size),
      ),
    );
  }
}
