import '../data/audio_repository.dart';

/// Thin abstraction over waveform / duration loading.
///
/// The `audio_waveforms` [PlayerController] handles actual waveform extraction
/// internally (via `preparePlayer`). This use-case acts as an abstraction layer
/// for obtaining the total duration independently of the UI controller — useful
/// for pre-validation and unit testing without instantiating a
/// [PlayerController].
class LoadWaveformUseCase {
  const LoadWaveformUseCase({required AudioRepository repository})
      : _repository = repository;

  final AudioRepository _repository;

  /// Returns the total [Duration] of the audio file at [filePath].
  ///
  /// Delegates to [AudioRepository.getAudioDuration] which uses FFprobeKit.
  /// Throws [AudioTrimException] if the duration cannot be determined.
  Future<Duration> getDuration(String filePath) async {
    return _repository.getAudioDuration(filePath);
  }
}
