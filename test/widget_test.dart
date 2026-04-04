import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trimr/app/app.dart';
import 'package:trimr/core/utils/format_utils.dart';
import 'package:trimr/features/trimmer/widgets/file_import_zone.dart';
import 'package:trimr/features/trimmer/screen/trimmer_view.dart';

void main() {
  group('FormatUtils', () {
    test('formatDuration formats correctly', () {
      expect(
        FormatUtils.formatDuration(
          const Duration(minutes: 1, seconds: 23, milliseconds: 400),
        ),
        '01:23.4',
      );
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

  group('Trimmer UI shell', () {
    testWidgets('TrimrApp boots into stage-based trimmer view', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TrimrApp()));
      await tester.pumpAndSettle();

      expect(find.byType(TrimmerView), findsOneWidget);
      expect(find.text('TRIMR'), findsOneWidget);
      expect(find.text('AUDIO TRIMMER'), findsOneWidget);
      expect(find.byType(FileImportZone), findsOneWidget);
      expect(find.text('SELECT AUDIO FILE'), findsOneWidget);
    });

    testWidgets('idle state keeps editor surfaces hidden', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TrimmerView())),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTROLS'), findsNothing);
      expect(find.text('FORMAT'), findsNothing);
      expect(find.text('DURATION'), findsNothing);
      expect(find.byType(FileImportZone), findsOneWidget);
      expect(find.text('TAP TO IMPORT'), findsOneWidget);
    });
  });
}
