class FormatUtils {
  FormatUtils._();

  /// Format duration to "MM:SS.T" (e.g., "01:23.4")
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  /// Format duration for display with hours if needed
  static String formatDurationLong(Duration d) {
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return formatDuration(d);
  }

  /// Format file size to human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format bitrate to human-readable string
  static String formatBitrate(int bitsPerSecond) {
    if (bitsPerSecond <= 0) return 'N/A';
    final kbps = bitsPerSecond / 1000;
    if (kbps < 1000) return '${kbps.round()} kbps';
    return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
  }
}
