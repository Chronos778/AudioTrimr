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
  final String exportPreset;
  final double exportProgress;
  final String? exportedPath;
  final String? errorMessage;
  final double zoomLevel;
  final bool loopEnabled;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final bool canUndo;
  final bool canRedo;

  const TrimmerState({
    this.status = TrimmerStatus.idle,
    this.metadata,
    this.waveform,
    this.trimStart = Duration.zero,
    this.trimEnd = Duration.zero,
    this.currentPosition = Duration.zero,
    this.selectedFormat = 'MP3',
    this.exportPreset = 'BALANCED',
    this.exportProgress = 0.0,
    this.exportedPath,
    this.errorMessage,
    this.zoomLevel = 1.0,
    this.loopEnabled = false,
    this.fadeInDuration = Duration.zero,
    this.fadeOutDuration = Duration.zero,
    this.canUndo = false,
    this.canRedo = false,
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
    String? exportPreset,
    double? exportProgress,
    String? exportedPath,
    String? errorMessage,
    double? zoomLevel,
    bool? loopEnabled,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
    bool? canUndo,
    bool? canRedo,
  }) {
    return TrimmerState(
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      waveform: waveform ?? this.waveform,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      currentPosition: currentPosition ?? this.currentPosition,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      exportPreset: exportPreset ?? this.exportPreset,
      exportProgress: exportProgress ?? this.exportProgress,
      exportedPath: exportedPath ?? this.exportedPath,
      errorMessage: errorMessage ?? this.errorMessage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      loopEnabled: loopEnabled ?? this.loopEnabled,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
      fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class _EditSnapshot {
  final Duration trimStart;
  final Duration trimEnd;
  final double zoomLevel;
  final bool loopEnabled;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final String selectedFormat;
  final String exportPreset;

  const _EditSnapshot({
    required this.trimStart,
    required this.trimEnd,
    required this.zoomLevel,
    required this.loopEnabled,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    required this.selectedFormat,
    required this.exportPreset,
  });
}

// ─── NOTIFIER ──────────────────────────────────────────────────
class TrimmerNotifier extends StateNotifier<TrimmerState> {
  final AudioService _audioService = AudioService();
  final List<_EditSnapshot> _undoStack = <_EditSnapshot>[];
  final List<_EditSnapshot> _redoStack = <_EditSnapshot>[];

  TrimmerNotifier() : super(const TrimmerState()) {
    // Listen to player position
    _audioService.player.positionStream.listen((position) {
      if (state.status == TrimmerStatus.playing ||
          state.status == TrimmerStatus.paused) {
        state = state.copyWith(currentPosition: position);
      }
    });

    // Listen to player state
    _audioService.player.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        if (state.loopEnabled && state.hasFile) {
          await _audioService.playSegment(state.trimStart, state.trimEnd);
          state = state.copyWith(
            status: TrimmerStatus.playing,
            currentPosition: Duration.zero,
          );
          return;
        }

        state = state.copyWith(
          status: TrimmerStatus.paused,
          currentPosition: Duration.zero,
        );
      }
    });
  }

  AudioService get audioService => _audioService;

  _EditSnapshot _snapshotFromState(TrimmerState s) {
    return _EditSnapshot(
      trimStart: s.trimStart,
      trimEnd: s.trimEnd,
      zoomLevel: s.zoomLevel,
      loopEnabled: s.loopEnabled,
      fadeInDuration: s.fadeInDuration,
      fadeOutDuration: s.fadeOutDuration,
      selectedFormat: s.selectedFormat,
      exportPreset: s.exportPreset,
    );
  }

  void _pushUndoSnapshot() {
    if (!state.hasFile) return;
    _undoStack.add(_snapshotFromState(state));
    if (_undoStack.length > 80) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _syncUndoRedoFlags();
  }

  void _syncUndoRedoFlags() {
    state = state.copyWith(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
    );
  }

  void _applySnapshot(_EditSnapshot snap) {
    state = state.copyWith(
      trimStart: snap.trimStart,
      trimEnd: snap.trimEnd,
      zoomLevel: snap.zoomLevel,
      loopEnabled: snap.loopEnabled,
      fadeInDuration: snap.fadeInDuration,
      fadeOutDuration: snap.fadeOutDuration,
      selectedFormat: snap.selectedFormat,
      exportPreset: snap.exportPreset,
      status: state.isPlaying ? TrimmerStatus.paused : state.status,
    );
  }

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
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        exportPreset: 'BALANCED',
      );

      _undoStack.clear();
      _redoStack.clear();
      _syncUndoRedoFlags();

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
    _pushUndoSnapshot();
    state = state.copyWith(trimStart: start);
  }

  void setTrimEnd(Duration end) {
    final maxDuration = state.metadata?.duration ?? Duration.zero;
    if (end > maxDuration) end = maxDuration;
    if (end <= state.trimStart) return;
    _pushUndoSnapshot();
    state = state.copyWith(trimEnd: end);
  }

  void setSelectedFormat(String format) {
    _pushUndoSnapshot();
    state = state.copyWith(selectedFormat: format);
  }

  void setExportPreset(String preset) {
    _pushUndoSnapshot();
    switch (preset) {
      case 'MP3_LOW':
      case 'MP3_HIGH':
        state = state.copyWith(exportPreset: preset, selectedFormat: 'MP3');
        break;
      case 'AAC_HIGH':
        state = state.copyWith(exportPreset: preset, selectedFormat: 'AAC');
        break;
      case 'WAV_MASTER':
        state = state.copyWith(exportPreset: preset, selectedFormat: 'WAV');
        break;
      default:
        state = state.copyWith(exportPreset: 'BALANCED');
    }
  }

  void setZoomLevel(double zoomLevel) {
    _pushUndoSnapshot();
    state = state.copyWith(zoomLevel: zoomLevel.clamp(1.0, 3.0));
  }

  void toggleLoop() {
    _pushUndoSnapshot();
    state = state.copyWith(loopEnabled: !state.loopEnabled);
  }

  void setFadeInDuration(Duration value) {
    final maxFade = Duration(milliseconds: state.trimmedDuration.inMilliseconds ~/ 2);
    final next = value < Duration.zero
        ? Duration.zero
        : (value > maxFade ? maxFade : value);
    _pushUndoSnapshot();
    state = state.copyWith(fadeInDuration: next);
  }

  void setFadeOutDuration(Duration value) {
    final maxFade = Duration(milliseconds: state.trimmedDuration.inMilliseconds ~/ 2);
    final next = value < Duration.zero
        ? Duration.zero
        : (value > maxFade ? maxFade : value);
    _pushUndoSnapshot();
    state = state.copyWith(fadeOutDuration: next);
  }

  void undoEdit() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshotFromState(state));
    final snap = _undoStack.removeLast();
    _applySnapshot(snap);
    _syncUndoRedoFlags();
  }

  void redoEdit() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshotFromState(state));
    final snap = _redoStack.removeLast();
    _applySnapshot(snap);
    _syncUndoRedoFlags();
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

  Future<void> playFromTrimStart() async {
    try {
      state = state.copyWith(status: TrimmerStatus.playing);
      await _audioService.seekTo(state.trimStart);
      await _audioService.playSegment(state.trimStart, state.trimEnd);
    } catch (e) {
      state = state.copyWith(
        status: TrimmerStatus.error,
        errorMessage: 'Playback error: ${e.toString()}',
      );
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
        exportPreset: state.exportPreset,
        fadeIn: state.fadeInDuration,
        fadeOut: state.fadeOutDuration,
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
    _undoStack.clear();
    _redoStack.clear();
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
