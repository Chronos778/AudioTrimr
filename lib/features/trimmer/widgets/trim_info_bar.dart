import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trimmer_provider.dart';

class TrimInfoBar extends ConsumerWidget {
  const TrimInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trimmerProvider);

    if (!state.hasFile ||
        state.status == TrimmerStatus.idle ||
        state.status == TrimmerStatus.loading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoChip(
            label: 'START',
            value: FormatUtils.formatDuration(state.trimStart),
            color: AppTheme.accentGreen,
          ),
          Container(
            width: 1,
            height: 28,
            color: AppTheme.borderColor,
          ),
          _InfoChip(
            label: 'END',
            value: FormatUtils.formatDuration(state.trimEnd),
            color: AppTheme.accentRed,
          ),
          Container(
            width: 1,
            height: 28,
            color: AppTheme.borderColor,
          ),
          _InfoChip(
            label: 'DURATION',
            value: FormatUtils.formatDuration(state.trimmedDuration),
            color: AppTheme.accentElec,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 400.ms);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.monoLabel.copyWith(
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.monoValue.copyWith(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
