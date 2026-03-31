import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../data/audio_repository.dart';
import '../domain/trim_audio_usecase.dart';
import 'trimmer_state.dart';

/// Business-logic layer for the Audio Trimmer.
///
/// The UI (TrimmerScreen) creates and manages its own [PlayerController]; the
/// cubit does NOT touch it directly. Instead, the UI calls
/// [setFileLoaded] once the controller has finished preparing the player,
/// supplying the resolved [Duration].
class TrimmerCubit extends Cubit<TrimmerState> {
  TrimmerCubit({
    required TrimAudioUseCase trimAudioUseCase,
    required AudioRepository audioRepository,
  })  : _trimAudioUseCase = trimAudioUseCase,
        _audioRepository = audioRepository,
        super(const TrimmerState());

  final TrimAudioUseCase _trimAudioUseCase;

  // ignore: unused_field — kept for future use (e.g., pre-flight duration check)
  final AudioRepository _audioRepository;

  // -------------------------------------------------------------------------
  // File picking
  // -------------------------------------------------------------------------

  /// Opens the system file picker filtered to audio files.
  ///
  /// Emits [TrimmerState.isLoading] = `true` while the picker is open /
  /// resolving. The UI must call [setFileLoaded] after the [PlayerController]
  /// has successfully prepared the player.
  ///
  /// Does nothing when the user cancels the picker.
  Future<void> pickFile() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result == null) {
        // User cancelled — restore previous loading state.
        emit(state.copyWith(isLoading: false));
        return;
      }

      final path = result.files.single.path;
      final name = result.files.single.name;

      if (path == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Could not resolve the file path for "$name".',
        ));
        return;
      }

      // Emit the path + name; totalDuration is filled in by setFileLoaded once
      // the PlayerController has prepared the audio.
      emit(state.copyWith(
        filePath: path,
        fileName: name,
        // Reset trim markers and playback state for the new file.
        totalDuration: Duration.zero,
        startDuration: Duration.zero,
        endDuration: Duration.zero,
        isPlaying: false,
        playheadPosition: Duration.zero,
        trimSuccess: false,
        clearSavedFilePath: true,
        clearErrorMessage: true,
        // isLoading stays true until setFileLoaded is called.
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to pick a file: $e',
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Post-load callback (called by the UI after PlayerController.preparePlayer)
  // -------------------------------------------------------------------------

  /// Called by the UI widget once [PlayerController.preparePlayer] completes
  /// successfully, confirming that [totalDuration] is now known.
  ///
  /// Sets the default trim range to the full file length.
  void setFileLoaded(String path, String name, Duration totalDuration) {
    emit(state.copyWith(
      filePath: path,
      fileName: name,
      totalDuration: totalDuration,
      startDuration: Duration.zero,
      endDuration: totalDuration,
      isPlaying: false,
      playheadPosition: Duration.zero,
      isLoading: false,
      trimSuccess: false,
      clearSavedFilePath: true,
      clearErrorMessage: true,
    ));
  }

  // -------------------------------------------------------------------------
  // Trim range updates
  // -------------------------------------------------------------------------

  /// Updates [TrimmerState.startDuration], clamping to `[0, endDuration)`.
  void updateStartTime(Duration d) {
    final clamped = _clampStart(d);
    emit(state.copyWith(startDuration: clamped));
  }

  /// Updates [TrimmerState.endDuration], clamping to `(startDuration, totalDuration]`.
  void updateEndTime(Duration d) {
    final clamped = _clampEnd(d);
    emit(state.copyWith(endDuration: clamped));
  }

  /// Maps a 0.0–1.0 range-slider pair onto [totalDuration] and updates both
  /// [TrimmerState.startDuration] and [TrimmerState.endDuration].
  ///
  /// [startFraction] and [endFraction] must both be in `[0.0, 1.0]`.
  void updateRange(double startFraction, double endFraction) {
    assert(startFraction >= 0.0 && startFraction <= 1.0,
        'startFraction must be in [0.0, 1.0]');
    assert(endFraction >= 0.0 && endFraction <= 1.0,
        'endFraction must be in [0.0, 1.0]');

    final totalMs = state.totalDuration.inMilliseconds;
    final rawStart =
        Duration(milliseconds: (startFraction * totalMs).round());
    final rawEnd = Duration(milliseconds: (endFraction * totalMs).round());

    final start = _clampStart(rawStart, end: rawEnd);
    final end = _clampEnd(rawEnd, start: rawStart);

    emit(state.copyWith(startDuration: start, endDuration: end));
  }

  // -------------------------------------------------------------------------
  // Playback
  // -------------------------------------------------------------------------

  /// Flips [TrimmerState.isPlaying].
  ///
  /// The UI is responsible for calling the corresponding [PlayerController]
  /// methods; this method simply signals the intended state.
  void togglePlayback() {
    emit(state.copyWith(isPlaying: !state.isPlaying));
  }

  /// Receives the current playhead position from a [PlayerController] stream
  /// subscription in the UI and stores it in state.
  void updatePlayheadPosition(Duration d) {
    if (d.inMilliseconds == state.playheadPosition.inMilliseconds) {
      return;
    }
    emit(state.copyWith(playheadPosition: d));
  }

  // -------------------------------------------------------------------------
  // Output format
  // -------------------------------------------------------------------------

  /// Selects the export [OutputFormat].
  void setOutputFormat(OutputFormat f) {
    emit(state.copyWith(outputFormat: f));
  }

  // -------------------------------------------------------------------------
  // Trim operation
  // -------------------------------------------------------------------------

  /// Runs the FFmpeg trim via [TrimAudioUseCase].
  ///
  /// Uses [getExternalStorageDirectory] (falling back to the app's temporary
  /// directory) as the output location. On success emits
  /// [TrimmerState.trimSuccess] = `true` and [TrimmerState.savedFilePath].
  /// On failure emits [TrimmerState.errorMessage].
  Future<void> trimAudio() async {
    if (!state.hasFile) {
      emit(state.copyWith(
        errorMessage: 'No file loaded. Please pick an audio file first.',
      ));
      return;
    }

    if (state.endDuration <= state.startDuration) {
      emit(state.copyWith(
        errorMessage:
            'Invalid trim range: end must be after start.',
      ));
      return;
    }

    emit(state.copyWith(
      isTrimming: true,
      trimSuccess: false,
      clearErrorMessage: true,
      clearSavedFilePath: true,
    ));

    try {
      // Resolve the output directory, with graceful fallback.
      String outputDir;
      try {
        final extDir = await getExternalStorageDirectory();
        outputDir = extDir?.path ?? (await getTemporaryDirectory()).path;
      } catch (_) {
        outputDir = (await getTemporaryDirectory()).path;
      }

      final savedPath = await _trimAudioUseCase(
        inputPath: state.filePath!,
        start: state.startDuration,
        end: state.endDuration,
        format: state.outputFormat,
        outputDir: outputDir,
      );

      emit(state.copyWith(
        isTrimming: false,
        trimSuccess: true,
        savedFilePath: savedPath,
      ));
    } on AudioTrimException catch (e) {
      emit(state.copyWith(
        isTrimming: false,
        errorMessage: e.message,
      ));
    } on ArgumentError catch (e) {
      emit(state.copyWith(
        isTrimming: false,
        errorMessage: e.message.toString(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isTrimming: false,
        errorMessage: 'Unexpected error during trim: $e',
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Error / reset helpers
  // -------------------------------------------------------------------------

  /// Clears [TrimmerState.errorMessage].
  void clearError() {
    emit(state.copyWith(clearErrorMessage: true));
  }

  /// Resets the cubit back to its initial (empty) state.
  void resetState() {
    emit(const TrimmerState());
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Duration _clampStart(Duration d, {Duration? end}) {
    final upper = (end ?? state.endDuration) - const Duration(milliseconds: 1);
    if (d.isNegative) return Duration.zero;
    if (upper.isNegative || d >= upper) {
      // Keep at least 1 ms gap.
      return upper.isNegative ? Duration.zero : upper;
    }
    return d;
  }

  Duration _clampEnd(Duration d, {Duration? start}) {
    final lower = (start ?? state.startDuration) + const Duration(milliseconds: 1);
    if (d > state.totalDuration) return state.totalDuration;
    if (d <= lower) return lower;
    return d;
  }
}
