import '../data/audio_repository.dart';

/// Use-case that validates trim parameters and delegates to [AudioRepository].
class TrimAudioUseCase {
  const TrimAudioUseCase({required AudioRepository repository})
      : _repository = repository;

  final AudioRepository _repository;

  /// Validates [start] and [end], then trims the audio file.
  ///
  /// Throws [ArgumentError] for invalid time ranges.
  /// Throws [AudioTrimException] when the underlying FFmpeg operation fails.
  ///
  /// Returns the absolute path of the trimmed output file.
  Future<String> call({
    required String inputPath,
    required Duration start,
    required Duration end,
    required OutputFormat format,
    required String outputDir,
  }) async {
    if (start.isNegative) {
      throw ArgumentError.value(
        start,
        'start',
        'Start time must be >= 0.',
      );
    }

    if (end <= start) {
      throw ArgumentError(
        'End time (${end.inMilliseconds} ms) must be greater than '
        'start time (${start.inMilliseconds} ms).',
      );
    }

    return _repository.trimAudio(
      inputPath: inputPath,
      start: start,
      end: end,
      format: format,
      outputDir: outputDir,
    );
  }
}
