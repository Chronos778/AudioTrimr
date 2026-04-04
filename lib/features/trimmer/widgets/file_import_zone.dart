import 'package:flutter/material.dart';
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

    return GestureDetector(
      onTap: isLoading ? null : () => _pickFile(context, ref),
      child: Container(
        width: double.infinity,
        height: 600,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          border: Border.all(color: AppTheme.accentBlue, width: 1.0),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        padding: const EdgeInsets.all(32),
        child: isLoading ? _buildLoadingState() : _buildIdleState(context, ref),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('IMPORTING AUDIO', style: AppTheme.monoDisplay.copyWith(fontSize: 28, color: AppTheme.accentBlue)),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: AppTheme.borderColor,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
        ),
      ],
    );
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('SELECT AUDIO FILE', style: AppTheme.monoDisplay.copyWith(fontSize: 28)),
        const SizedBox(height: 24),
        Text(
          'TAP TO IMPORT',
          style: AppTheme.monoLabel.copyWith(color: AppTheme.accentBlue, letterSpacing: 1.5),
        ),
        const SizedBox(height: 48),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: const [
            _FormatTag('MP3'),
            _FormatTag('WAV'),
            _FormatTag('FLAC'),
            _FormatTag('M4A'),
            _FormatTag('AAC'),
          ],
        )
      ],
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    if (context.mounted) {
      final hasPermission = await PermissionService.requestStoragePermissions(context);
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
            content: Text('ERR: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
}

class _FormatTag extends StatelessWidget {
  final String format;
  const _FormatTag(this.format);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: AppTheme.bgPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(format, style: AppTheme.monoLabel.copyWith(color: AppTheme.textMuted, letterSpacing: 1.0)),
    );
  }
}
