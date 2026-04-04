import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('CONTROLS', style: AppTheme.monoLabel),
              const Spacer(),
              _TextBtn(label: 'UNDO', enabled: state.canUndo, onTap: notifier.undoEdit),
              const SizedBox(width: 8),
              _TextBtn(label: 'REDO', enabled: state.canRedo, onTap: notifier.redoEdit),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _ActionBlock(
                  label: 'RESET',
                  backgroundColor: AppTheme.bgPrimary,
                  foregroundColor: AppTheme.textPrimary,
                  onTap: () => notifier.restart(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _ActionBlock(
                  label: state.isPlaying ? 'PAUSE' : 'PLAY',
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: AppTheme.bgPrimary,
                  onTap: () => notifier.togglePlayPause(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBlock(
                  label: 'STOP',
                  backgroundColor: AppTheme.bgPrimary,
                  foregroundColor: AppTheme.accentRed,
                  onTap: () async {
                    await notifier.pause();
                    notifier.seekToPosition(Duration.zero);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('LOOP', style: AppTheme.monoLabel),
                    const SizedBox(width: 8),
                    Switch(
                      value: state.loopEnabled,
                      onChanged: (_) => notifier.toggleLoop(),
                      activeThumbColor: AppTheme.bgPrimary,
                      activeTrackColor: AppTheme.accentBlue,
                      inactiveThumbColor: AppTheme.textMuted,
                      inactiveTrackColor: AppTheme.bgElevated,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text('ZOOM', style: AppTheme.monoLabel),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, disabledThumbRadius: 0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                          tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
                          activeTrackColor: AppTheme.accentBlue,
                          inactiveTrackColor: AppTheme.borderColor,
                          thumbColor: AppTheme.accentBlue,
                        ),
                        child: Slider(
                          value: state.zoomLevel,
                          min: 1.0,
                          max: 3.0,
                          onChanged: notifier.setZoomLevel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _TextBtn({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Text(
        label,
        style: AppTheme.monoLabel.copyWith(
          color: enabled ? AppTheme.textPrimary : AppTheme.borderColor,
        ),
      ),
    );
  }
}

class _ActionBlock extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionBlock({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  State<_ActionBlock> createState() => _ActionBlockState();
}

class _ActionBlockState extends State<_ActionBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _controller.forward();
  }

  void _onTapUp(_) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTheme.monoValue.copyWith(
              color: widget.foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
