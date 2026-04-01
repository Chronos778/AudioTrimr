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

    return GestureDetector(
      onTap: state.status == TrimmerStatus.loading
          ? null
          : () => _pickFile(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: state.status == TrimmerStatus.loading
                ? AppTheme.accentElec.withValues(alpha: 0.5)
                : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: state.status == TrimmerStatus.loading
            ? _buildLoadingState()
            : _buildIdleState(),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 100.ms);
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.accentElec),
          ),
        ),
        const SizedBox(height: 12),
        Text('LOADING AUDIO...', style: AppTheme.monoLabel),
      ],
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Icon(
          Icons.audio_file_outlined,
          size: 32,
          color: AppTheme.accentElec.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        Text(
          'TAP TO IMPORT AUDIO',
          style: AppTheme.monoLabel.copyWith(
            color: AppTheme.accentElec,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'MP3 · WAV · M4A · AAC · OGG · FLAC',
          style: AppTheme.monoLabel.copyWith(fontSize: 10),
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
