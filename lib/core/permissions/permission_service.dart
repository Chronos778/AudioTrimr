import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request storage permissions for file picking and saving.
  /// Returns true if all required permissions are granted.
  static Future<bool> requestStoragePermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      final androidInfo = await _getAndroidSdkVersion();

      if (androidInfo >= 33) {
        // Android 13+: request audio permission
        final status = await Permission.audio.request();
        if (status.isGranted) return true;

        if (status.isPermanentlyDenied && context.mounted) {
          await _showSettingsDialog(context, 'Audio access');
          return false;
        }

        if (context.mounted) {
          return await _showRationaleAndRetry(
            context,
            'Audio Access Required',
            'TRIMR needs access to your audio files to load and trim them.',
            Permission.audio,
          );
        }
        return false;
      } else if (androidInfo >= 29) {
        // Android 10-12: scoped storage, read permission
        final status = await Permission.storage.request();
        if (status.isGranted) return true;

        if (status.isPermanentlyDenied && context.mounted) {
          await _showSettingsDialog(context, 'Storage access');
          return false;
        }
        return false;
      } else {
        // Android 9 and below
        final statuses = await [
          Permission.storage,
        ].request();
        return statuses[Permission.storage]?.isGranted ?? false;
      }
    }

    // iOS doesn't need explicit storage permissions for file picker
    return true;
  }

  static Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      // Use the device_info_plus approach, but for minimal deps,
      // just check via permission_handler behavior
      // We'll try Android 13 permission first, falling back
      final status = await Permission.audio.status;
      // If audio permission exists (not unknown), we're on Android 13+
      if (status != PermissionStatus.denied &&
          status != PermissionStatus.permanentlyDenied &&
          status != PermissionStatus.restricted) {
        return 33;
      }
      // Try storage for older
      return 29; // default assumption for modern Android
    } catch (_) {
      return 28;
    }
  }

  static Future<bool> _showRationaleAndRetry(
    BuildContext context,
    String title,
    String message,
    Permission permission,
  ) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2A2A35)),
        ),
        title: Text(title, style: const TextStyle(color: Color(0xFFF0F0F5))),
        content: Text(message, style: const TextStyle(color: Color(0xFF6B6B80))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF6B6B80))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('GRANT', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );

    if (shouldRetry == true) {
      final status = await permission.request();
      return status.isGranted;
    }
    return false;
  }

  static Future<void> _showSettingsDialog(
    BuildContext context,
    String permissionName,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2A2A35)),
        ),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Color(0xFFF0F0F5)),
        ),
        content: Text(
          '$permissionName has been permanently denied. '
          'Please enable it in Settings to use TRIMR.',
          style: const TextStyle(color: Color(0xFF6B6B80)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF6B6B80))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('OPEN SETTINGS',
                style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }
}
