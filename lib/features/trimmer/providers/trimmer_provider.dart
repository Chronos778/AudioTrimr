import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/audio/audio_service.dart';

// ─── STATE ─────────────────────────────────────────────────────
enum TrimmerStatus {
  idle,
  loading,
  loaded,
  playing,
  paused,
  exporting,
  exported,
  error,
}

class TrimmerState {
  final TrimmerStatus status;
  final AudioMetadata? metadata;
  final WaveformData? waveform;
  final Duration trimStart;
  final Duration trimEnd;
  final Duration currentPosition;
  final String selectedFormat;
  final double exportProgress;
  final String? exportedPath;
  final String? errorMessage;

  const TrimmerState({
    this.status = TrimmerStatus.idle,
    this.metadata,
    this.waveform,
    this.trimStart = Duration.zero,
    this.trimEnd = Duration.zero,
    this.currentPosition = Duration.zero,
    this.selectedFormat = 'MP3',
    this.exportProgress = 0.0,
    this.exportedPath,
    this.errorMessage,
  });

  Duration get trimmedDuration => trimEnd - trimStart;
  bool get hasFile => metadata != null;
  bool get isPlaying => status == TrimmerStatus.playing;

  TrimmerState copyWith({
    TrimmerStatus? status,
    AudioMetadata? metadata,
    WaveformData? waveform,
    Duration? trimStart,
    Duration? trimEnd,
    Duration? currentPosition,
    String? selectedFormat,
    double? exportProgress,
    String? exportedPath,
    String? errorMessage,
  }) {
    return TrimmerState(
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      waveform: waveform ?? this.waveform,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      currentPosition: currentPosition ?? this.currentPosition,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      exportProgress: exportProgress ?? this.exportProgress,
      exportedPath: exportedPath ?? this.exportedPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── NOTIFIER ──────────────────────────────────────────────────
class TrimmerNotifier extends StateNotifier<TrimmerState> {
  final AudioService _audioService = AudioService();

  TrimmerNotifier() : super(const TrimmerState()) {
    // Listen to player position
    _audioService.player.positionStream.listen((position) {
      if (state.status == TrimmerStatus.playing ||
          state.status == TrimmerStatus.paused) {
        state = state.copyWith(currentPosition: position);
      }
    });

    // Listen to player state
    _audioService.player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          status: TrimmerStatus.paused,
          currentPosition: Duration.zero,
        );
      }
    });
  }

  AudioService get audioService => _audioService;

  Future<void> loadFile(String filePath) async {
    state = state.copyWith(
      status: TrimmerStatus.loading,
      errorMessage: null,
      exportedPath: null,
    );

    try {
      final metadata = await _audioService.loadFile(filePath);

      // Check file size warning (>500MB)
      if (metadata.fileSize > 500 * 1024 * 1024) {
        // Still allow, just note it
      }

      state = state.copyWith(
        status: TrimmerStatus.loaded,
        metadata: metadata,
        trimStart: Duration.zero,
        trimEnd: metadata.duration,
        currentPosition: Duration.zero,
      );

      // Extract waveform in background
      _extractWaveform(filePath);
    } catch (e) {
      state = state.copyWith(
        status: TrimmerStatus.error,
        errorMessage: 'Failed to load audio: ${e.toString()}',
      );
    }
  }

  Future<void> _extractWaveform(String filePath) async {
    try {
      final waveform = await _audioService.extractWaveform(filePath, 200);
      state = state.copyWith(waveform: waveform);
    } catch (_) {
      // Waveform extraction failure is non-critical
    }
  }

  void setTrimStart(Duration start) {
    if (start < Duration.zero) start = Duration.zero;
    if (start >= state.trimEnd) return;
    state = state.copyWith(trimStart: start);
  }

  void setTrimEnd(Duration end) {
    final maxDuration = state.metadata?.duration ?? Duration.zero;
    if (end > maxDuration) end = maxDuration;
    if (end <= state.trimStart) return;
    state = state.copyWith(trimEnd: end);
  }

  void setSelectedFormat(String format) {
    state = state.copyWith(selectedFormat: format);
  }

  Future<void> playTrimmed() async {
    try {
      state = state.copyWith(status: TrimmerStatus.playing);
      await _audioService.playSegment(state.trimStart, state.trimEnd);
    } catch (e) {
      state = state.copyWith(
        status: TrimmerStatus.error,
        errorMessage: 'Playback error: ${e.toString()}',
      );
    }
  }

  Future<void> pause() async {
    state = state.copyWith(status: TrimmerStatus.paused);
    await _audioService.pause();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await playTrimmed();
    }
  }

  Future<void> restart() async {
    await _audioService.seekTo(Duration.zero);
    if (state.status != TrimmerStatus.playing) {
      await playTrimmed();
    }
  }

  void seekToPosition(Duration position) {
    _audioService.seekTo(position);
    state = state.copyWith(currentPosition: position);
  }

  Future<void> exportTrimmed() async {
    if (state.metadata == null) return;

    state = state.copyWith(
      status: TrimmerStatus.exporting,
      exportProgress: 0.0,
      errorMessage: null,
    );

    try {
      // Stop playback first
      await _audioService.stop();

      final outputPath = await _audioService.trimAudio(
        inputPath: state.metadata!.filePath,
        start: state.trimStart,
        end: state.trimEnd,
        outputFormat: state.selectedFormat.toLowerCase(),
        onProgress: (progress) {
          state = state.copyWith(exportProgress: progress);
        },
      );

      state = state.copyWith(
        status: TrimmerStatus.exported,
        exportedPath: outputPath,
        exportProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrimmerStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetForNewFile() {
    _audioService.stop();
    state = const TrimmerState();
  }

  void clearError() {
    state = state.copyWith(
      status: state.hasFile ? TrimmerStatus.loaded : TrimmerStatus.idle,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

// ─── PROVIDER ──────────────────────────────────────────────────
final trimmerProvider =
    StateNotifierProvider<TrimmerNotifier, TrimmerState>((ref) {
  return TrimmerNotifier();
});
