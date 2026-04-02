import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme.dart';
import '../../../../core/permissions/permission_service.dart';
import '../providers/trimmer_provider.dart';

class FileImportZone extends ConsumerWidget {
  const FileImportZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trimmerProvider);
    final isLoading = state.status == TrimmerStatus.loading;

    return AnimatedContainer(
      duration: AppTheme.mediumDuration,
      curve: AppTheme.emphasisCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.panelDecoration(
        tint: isLoading ? AppTheme.bgElevated : AppTheme.bgPanel,
        elevated: true,
      ),
      child: Semantics(
        button: !isLoading,
        enabled: !isLoading,
        label: isLoading ? 'Loading audio file' : 'Import audio file',
        hint: isLoading
            ? 'Please wait while the app loads the source file'
            : 'Opens the file picker and requests storage access if needed',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : () => _pickFile(context, ref),
            borderRadius: AppTheme.panelRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: AnimatedSwitcher(
                duration: AppTheme.mediumDuration,
                switchInCurve: AppTheme.emphasisCurve,
                switchOutCurve: AppTheme.revealCurve,
                child: isLoading
                    ? _buildLoadingState()
                    : _buildIdleState(context, ref),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0, duration: 320.ms);
  }

  Widget _buildLoadingState() {
    return Column(
      key: const ValueKey('loading'),
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentElec),
          ),
        ),
        const SizedBox(height: 14),
        Text('LOADING AUDIO', style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec)),
        const SizedBox(height: 6),
        Text(
          'Reading metadata and preparing the waveform workspace.',
          style: AppTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('idle'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentElec.withValues(alpha: 0.12),
            border: Border.all(color: AppTheme.accentElec.withValues(alpha: 0.45)),
          ),
          child: Icon(
            Icons.audio_file_outlined,
            size: 30,
            color: AppTheme.accentElec,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'IMPORT A SOURCE TRACK',
          style: AppTheme.monoLabel.copyWith(color: AppTheme.accentElec),
        ),
        const SizedBox(height: 8),
        Text(
          'MP3 · WAV · M4A · AAC · OGG · FLAC',
          style: AppTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _pickFile(context, ref),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Choose audio file'),
        ),
      ],
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    // Request permissions first
    if (context.mounted) {
      final hasPermission =
          await PermissionService.requestStoragePermissions(context);
      if (!hasPermission) return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        ref.read(trimmerProvider.notifier).loadFile(path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
}
