import 'package:flutter_test/flutter_test.dart';
import 'package:trimr/core/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    test('formatDuration formats correctly', () {
      expect(FormatUtils.formatDuration(const Duration(minutes: 1, seconds: 23, milliseconds: 400)), '01:23.4');
      expect(FormatUtils.formatDuration(Duration.zero), '00:00.0');
    });

    test('formatFileSize formats correctly', () {
      expect(FormatUtils.formatFileSize(512), '512 B');
      expect(FormatUtils.formatFileSize(1536), '1.5 KB');
      expect(FormatUtils.formatFileSize(1048576), '1.0 MB');
    });

    test('formatBitrate formats correctly', () {
      expect(FormatUtils.formatBitrate(128000), '128 kbps');
      expect(FormatUtils.formatBitrate(320000), '320 kbps');
      expect(FormatUtils.formatBitrate(0), 'N/A');
    });
  });
}
