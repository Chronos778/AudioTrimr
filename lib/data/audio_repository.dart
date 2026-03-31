import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';

// ---------------------------------------------------------------------------
// OutputFormat enum
// ---------------------------------------------------------------------------

/// The container / codec format used when exporting a trimmed clip.
enum OutputFormat {
  mp3,
  aac,
  wav;

  /// File-extension string (without the leading dot).
  String get extension {
    switch (this) {
      case OutputFormat.mp3:
        return 'mp3';
      case OutputFormat.aac:
        return 'aac';
      case OutputFormat.wav:
        return 'wav';
    }
  }

  /// Human-readable display name shown in the UI.
  String get displayName {
    switch (this) {
      case OutputFormat.mp3:
        return 'MP3';
      case OutputFormat.aac:
        return 'AAC';
      case OutputFormat.wav:
        return 'WAV';
    }
  }

  /// FFmpeg codec flags for this format.
  String get _codecFlags {
    switch (this) {
      case OutputFormat.mp3:
        return '-c:a libmp3lame -q:a 2';
      case OutputFormat.aac:
        return '-c:a aac -b:a 192k';
      case OutputFormat.wav:
        return '-c:a pcm_s16le';
    }
  }
}

// ---------------------------------------------------------------------------
// AudioTrimException
// ---------------------------------------------------------------------------

/// Thrown by [AudioRepository] when an FFmpeg trim operation fails.
class AudioTrimException implements Exception {
  const AudioTrimException(this.message);

  final String message;

  @override
  String toString() => 'AudioTrimException: $message';
}

// ---------------------------------------------------------------------------
// AudioRepository
// ---------------------------------------------------------------------------

/// Low-level data layer that wraps FFmpegKit / FFprobeKit operations.
class AudioRepository {
  // -------------------------------------------------------------------------
  // getAudioDuration
  // -------------------------------------------------------------------------

  /// Returns the total [Duration] of the audio file at [filePath].
  ///
  /// Uses [FFprobeKit.getMediaInformation] to read container metadata.
  /// Throws [AudioTrimException] if the duration cannot be determined.
  Future<Duration> getAudioDuration(String filePath) async {
    final session = await FFprobeKit.getMediaInformation(filePath);
    final info = session.getMediaInformation();

    if (info == null) {
      throw AudioTrimException(
        'FFprobe could not read media information for "$filePath".',
      );
    }

    final durationStr = info.getDuration();
    if (durationStr == null) {
      throw AudioTrimException(
        'FFprobe returned null duration for "$filePath".',
      );
    }

    final durationSeconds = double.tryParse(durationStr);
    if (durationSeconds == null) {
      throw AudioTrimException(
        'FFprobe returned an unparseable duration value: "$durationStr".',
      );
    }

    return Duration(microseconds: (durationSeconds * 1e6).round());
  }

  // -------------------------------------------------------------------------
  // trimAudio
  // -------------------------------------------------------------------------

  /// Trims [inputPath] between [start] and [end], encodes to [format], and
  /// writes the result into [outputDir].
  ///
  /// Returns the absolute path of the newly created file.
  ///
  /// The output filename has the form `trimmed_<timestamp>.<ext>`.
  /// [outputDir] is created automatically when it does not already exist.
  ///
  /// Throws [AudioTrimException] when FFmpeg exits with a non-zero return code,
  /// attaching the last few log lines to the exception message.
  Future<String> trimAudio({
    required String inputPath,
    required Duration start,
    required Duration end,
    required OutputFormat format,
    required String outputDir,
  }) async {
    // Ensure the output directory exists.
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Build output file path.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath =
        '$outputDir/trimmed_$timestamp.${format.extension}';

    // Convert durations to seconds (FFmpeg -ss / -to accept seconds).
    final startSec = start.inMilliseconds / 1000.0;
    final endSec = end.inMilliseconds / 1000.0;

    // Build the FFmpeg command.
    // -y          : overwrite output without prompting
    // -i          : input file
    // -map 0:a:0  : keep only first audio stream (drop cover-art/video streams)
    // -vn -sn -dn : disable video, subtitle, and data streams
    // -ss / -to   : trim window (seek before demux for accuracy)
    // <codecFlags>: format-specific codec settings
    // <output>    : output path
    final command =
      '-y -i "$inputPath" -map 0:a:0 -vn -sn -dn -ss $startSec -to $endSec ${format._codecFlags} "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }

    // Collect the tail of the session log for diagnostic purposes.
    final logs = await session.getLogs();
    final logTail = logs.length > 20
        ? logs.sublist(logs.length - 20)
        : logs;
    final logMessages = logTail.map((l) => l.getMessage()).join('\n');

    throw AudioTrimException(
      'FFmpeg exited with code ${returnCode?.getValue() ?? "unknown"}.\n'
      'Last log lines:\n$logMessages',
    );
  }
}
