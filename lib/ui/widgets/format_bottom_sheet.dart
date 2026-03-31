import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/trimmer_cubit.dart';
import '../../cubit/trimmer_state.dart';
import '../../data/audio_repository.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

/// Shows a modal bottom sheet that lets the user select the output format.
///
/// Reads the currently selected [OutputFormat] from [TrimmerCubit] and calls
/// [TrimmerCubit.setOutputFormat] when the user picks a different format.
void showFormatBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      // Pass the parent context so that BlocProvider is in scope.
      return BlocProvider.value(
        value: context.read<TrimmerCubit>(),
        child: const _FormatBottomSheet(),
      );
    },
  );
}

// ── Private sheet widget ──────────────────────────────────────────────────────

class _FormatBottomSheet extends StatelessWidget {
  const _FormatBottomSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrimmerCubit, TrimmerState>(
      buildWhen: (prev, curr) => prev.outputFormat != curr.outputFormat,
      builder: (context, state) {
        final cubit = context.read<TrimmerCubit>();

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ──────────────────────────────────────────
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.audio_file_rounded,
                        color: Color(0xFF1DB954),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Output Format',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade800, height: 1),
                const SizedBox(height: 4),

                // ── Format tiles ─────────────────────────────────────────
                ..._formatOptions.map((option) {
                  final bool isSelected = state.outputFormat == option.format;
                  return _FormatTile(
                    option: option,
                    isSelected: isSelected,
                    onTap: () {
                      cubit.setOutputFormat(option.format);
                      Navigator.of(context).pop();
                    },
                  );
                }),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Format tile ───────────────────────────────────────────────────────────────

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _FormatOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
      tileColor: isSelected
          ? const Color(0xFF1DB954).withOpacity(0.08)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954).withOpacity(0.15)
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: const Color(0xFF1DB954).withOpacity(0.4))
              : null,
        ),
        child: Center(
          child: Text(
            option.extension.toUpperCase(),
            style: TextStyle(
              color: isSelected ? const Color(0xFF1DB954) : Colors.grey.shade300,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
      title: Text(
        option.displayName,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1DB954) : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        option.description,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: Color(0xFF1DB954), size: 22)
          : Icon(Icons.radio_button_unchecked_rounded,
              color: Colors.grey.shade700, size: 22),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _FormatOption {
  const _FormatOption({
    required this.format,
    required this.displayName,
    required this.extension,
    required this.description,
  });

  final OutputFormat format;
  final String displayName;
  final String extension;
  final String description;
}

const List<_FormatOption> _formatOptions = [
  _FormatOption(
    format: OutputFormat.mp3,
    displayName: 'MP3',
    extension: '.mp3',
    description:
        'MPEG Audio Layer III — widely compatible, smaller file size',
  ),
  _FormatOption(
    format: OutputFormat.aac,
    displayName: 'AAC',
    extension: '.aac',
    description: 'Advanced Audio Coding — better quality than MP3 at same bitrate',
  ),
  _FormatOption(
    format: OutputFormat.wav,
    displayName: 'WAV',
    extension: '.wav',
    description: 'Waveform Audio — lossless, larger file size, maximum quality',
  ),
];
