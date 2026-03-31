import 'package:equatable/equatable.dart';

import '../data/audio_repository.dart';

/// Immutable state for [TrimmerCubit].
class TrimmerState extends Equatable {
  const TrimmerState({
    this.filePath,
    this.fileName,
    this.totalDuration = Duration.zero,
    this.startDuration = Duration.zero,
    this.endDuration = Duration.zero,
    this.isPlaying = false,
    this.playheadPosition = Duration.zero,
    this.isTrimming = false,
    this.trimSuccess = false,
    this.outputFormat = OutputFormat.mp3,
    this.errorMessage,
    this.savedFilePath,
    this.isLoading = false,
  });

  /// Absolute path of the currently loaded audio file. `null` means no file
  /// has been loaded yet.
  final String? filePath;

  /// Display name (basename) of the currently loaded audio file.
  final String? fileName;

  /// Total duration of the loaded audio.
  final Duration totalDuration;

  /// The trim region start position.
  final Duration startDuration;

  /// The trim region end position.
  final Duration endDuration;

  /// Whether the audio is currently playing back (inside the trim region).
  final bool isPlaying;

  /// Current playhead position reported by the player.
  final Duration playheadPosition;

  /// True while an FFmpeg trim operation is in progress.
  final bool isTrimming;

  /// Set to `true` after a successful trim; reset on the next operation.
  final bool trimSuccess;

  /// The desired output format for trimmed files.
  final OutputFormat outputFormat;

  /// Non-null when an error has occurred; displayed to the user.
  final String? errorMessage;

  /// Absolute path of the most recently saved trimmed file.
  final String? savedFilePath;

  /// True while a file is being picked / loaded.
  final bool isLoading;

  // -------------------------------------------------------------------------
  // Derived helpers
  // -------------------------------------------------------------------------

  /// True when a file has been fully loaded and is ready for trimming.
  bool get hasFile => filePath != null && totalDuration > Duration.zero;

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  TrimmerState copyWith({
    String? filePath,
    bool clearFilePath = false,
    String? fileName,
    bool clearFileName = false,
    Duration? totalDuration,
    Duration? startDuration,
    Duration? endDuration,
    bool? isPlaying,
    Duration? playheadPosition,
    bool? isTrimming,
    bool? trimSuccess,
    OutputFormat? outputFormat,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? savedFilePath,
    bool clearSavedFilePath = false,
    bool? isLoading,
  }) {
    return TrimmerState(
      filePath: clearFilePath ? null : filePath ?? this.filePath,
      fileName: clearFileName ? null : fileName ?? this.fileName,
      totalDuration: totalDuration ?? this.totalDuration,
      startDuration: startDuration ?? this.startDuration,
      endDuration: endDuration ?? this.endDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      playheadPosition: playheadPosition ?? this.playheadPosition,
      isTrimming: isTrimming ?? this.isTrimming,
      trimSuccess: trimSuccess ?? this.trimSuccess,
      outputFormat: outputFormat ?? this.outputFormat,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      savedFilePath:
          clearSavedFilePath ? null : savedFilePath ?? this.savedFilePath,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // -------------------------------------------------------------------------
  // Equatable
  // -------------------------------------------------------------------------

  @override
  List<Object?> get props => [
        filePath,
        fileName,
        totalDuration,
        startDuration,
        endDuration,
        isPlaying,
        playheadPosition,
        isTrimming,
        trimSuccess,
        outputFormat,
        errorMessage,
        savedFilePath,
        isLoading,
      ];
}
