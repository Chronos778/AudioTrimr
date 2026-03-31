import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:share_plus/share_plus.dart';

import '../cubit/trimmer_cubit.dart';
import '../cubit/trimmer_state.dart';
import '../data/audio_repository.dart';
import '../utils/time_utils.dart';
import 'widgets/format_bottom_sheet.dart';
import 'widgets/playback_bar.dart';
import 'widgets/trim_controls.dart';
import 'widgets/waveform_widget.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class TrimmerScreen extends StatefulWidget {
  const TrimmerScreen({super.key});

  @override
  State<TrimmerScreen> createState() => _TrimmerScreenState();
}

class _TrimmerScreenState extends State<TrimmerScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final PlayerController _playerController;
  late final ja.AudioPlayer _audioPlayer;

  // ── Subscriptions ────────────────────────────────────────────────────────────
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<ja.PlaybackEvent>? _playbackEventSub;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  Timer? _syntheticPlayheadTicker;
  DateTime? _syntheticAnchorTime;
  Duration _syntheticAnchorPosition = Duration.zero;
  int _lastWaveformSyncMs = -1;

  // ── Cached prev state for BlocListener comparisons ───────────────────────────
  String? _prevFilePath;
  bool _prevIsPlaying = false;
  bool _prevTrimSuccess = false;
  String? _prevErrorMessage;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _audioPlayer = ja.AudioPlayer();
  }

  @override
  void dispose() {
    _syntheticPlayheadTicker?.cancel();
    _positionSub?.cancel();
    _playbackEventSub?.cancel();
    _playerStateSub?.cancel();
    _playerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Permission + file pick ────────────────────────────────────────────────────

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null) return; // user cancelled
    if (!mounted) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web file trimming is not supported in this build.'),
        ),
      );
      return;
    }

    final String? path = result.files.single.path;
    final String name = result.files.single.name;

    if (path == null) {
      context.read<TrimmerCubit>().clearError();
      return;
    }

    // Signal loading state — the BlocListener will respond to filePath change.
    // We call setFileLoaded AFTER preparePlayer so the duration is known.
    await _loadFile(context, path: path, name: name);
  }

  Future<void> _loadFile(
    BuildContext context, {
    required String path,
    required String name,
  }) async {
    final cubit = context.read<TrimmerCubit>();

    try {
      // Stop any current playback.
      await _stopPlayback();

      // Prepare waveform player — extracts waveform and loads file.
      await _playerController.preparePlayer(
        path: path,
        noOfSamples: 200,
        shouldExtractWaveform: true,
      );

      // Retrieve duration from waveform controller (most reliable source).
      final int durationMs =
          await _playerController.getDuration(DurationType.max);

      final Duration totalDuration = durationMs > 0
          ? Duration(milliseconds: durationMs)
          : Duration.zero;

      cubit.setFileLoaded(path, name, totalDuration);
      _syncWaveformPlayhead(Duration.zero);
    } catch (e) {
      cubit.setFileLoaded(path, name, Duration.zero);
    }
  }

  void _syncWaveformPlayhead(Duration position) {
    final int ms = position.inMilliseconds;
    if (ms == _lastWaveformSyncMs) return;
    _lastWaveformSyncMs = ms;

    unawaited(
      _playerController.seekTo(ms).catchError((_) {
        // Best-effort sync. Ignore transient controller timing errors.
      }),
    );
  }

  // ── Playback helpers ──────────────────────────────────────────────────────────

  Future<void> _startPlayback(TrimmerState state) async {
    if (state.filePath == null) return;

    await _positionSub?.cancel();
    _positionSub = null;
    await _playbackEventSub?.cancel();
    _playbackEventSub = null;
    _syntheticPlayheadTicker?.cancel();
    _syntheticPlayheadTicker = null;

    final cubit = context.read<TrimmerCubit>();

    try {
      await _audioPlayer.setFilePath(state.filePath!);

      // Seek to current playhead within the selected trim window.
      final Duration seekTo = state.playheadPosition >= state.startDuration &&
              state.playheadPosition <= state.endDuration
          ? state.playheadPosition
          : state.startDuration;
      await _audioPlayer.seek(seekTo);

        _syntheticAnchorPosition = seekTo;
        _syntheticAnchorTime = DateTime.now();

      // Update playhead on playback events (reliable on Android, including
      // pause/resume and completion boundaries).
      _playbackEventSub = _audioPlayer.playbackEventStream.listen((event) {
        if (!mounted) return;
        final currentState = cubit.state;
        final absolutePos = _normalizeAbsolutePosition(
          event.updatePosition,
          currentState,
        );
        _syntheticAnchorPosition = absolutePos;
        _syntheticAnchorTime = DateTime.now();
        cubit.updatePlayheadPosition(absolutePos);
        _syncWaveformPlayhead(absolutePos);

        if (currentState.isPlaying &&
            (absolutePos >= currentState.endDuration ||
                event.processingState == ja.ProcessingState.completed)) {
          cubit.togglePlayback();
        }
      });

      // High-frequency position stream for smooth slider movement.
      _positionSub = _audioPlayer
          .createPositionStream(
            minPeriod: const Duration(milliseconds: 33),
            maxPeriod: const Duration(milliseconds: 120),
          )
          .listen((Duration rawPos) {
        if (!mounted) return;
        final currentState = cubit.state;
        final absolutePos = _normalizeAbsolutePosition(rawPos, currentState);
        _syntheticAnchorPosition = absolutePos;
        _syntheticAnchorTime = DateTime.now();
        cubit.updatePlayheadPosition(absolutePos);
        _syncWaveformPlayhead(absolutePos);
      });

      _syntheticPlayheadTicker = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          if (!mounted) return;
          final currentState = cubit.state;
          if (!currentState.isPlaying) return;
          final anchorTime = _syntheticAnchorTime;
          if (anchorTime == null) return;

          final elapsed = DateTime.now().difference(anchorTime);
          final estimated = _normalizeAbsolutePosition(
            _syntheticAnchorPosition + elapsed,
            currentState,
          );
          cubit.updatePlayheadPosition(estimated);
          _syncWaveformPlayhead(estimated);

          if (estimated >= currentState.endDuration) {
            cubit.togglePlayback();
          }
        },
      );

      await _audioPlayer.play();
    } catch (e) {
      // If playback setup fails silently, toggle back so UI is consistent.
      if (mounted) cubit.togglePlayback();
    }
  }

  Future<void> _stopPlayback() async {
    _syntheticPlayheadTicker?.cancel();
    _syntheticPlayheadTicker = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _playbackEventSub?.cancel();
    _playbackEventSub = null;
    await _audioPlayer.pause();

    final cubit = context.read<TrimmerCubit>();
    final currentState = cubit.state;
    final finalPos = _normalizeAbsolutePosition(_audioPlayer.position, currentState);
    _syntheticAnchorPosition = finalPos;
    _syntheticAnchorTime = null;
    cubit.updatePlayheadPosition(finalPos);
    _syncWaveformPlayhead(finalPos);
  }

  Duration _normalizeAbsolutePosition(Duration rawPos, TrimmerState state) {
    // Playback runs on the source timeline; clamp to selected trim window.
    final Duration absolute = rawPos;

    if (absolute < state.startDuration) return state.startDuration;
    if (absolute > state.endDuration) return state.endDuration;
    return absolute;
  }

  // ── Seek callback (from PlaybackBar) ─────────────────────────────────────────

  Future<void> _onSeek(Duration position) async {
    final cubit = context.read<TrimmerCubit>();
    cubit.updatePlayheadPosition(position);
    _syncWaveformPlayhead(position);

    _syntheticAnchorPosition = position;
    _syntheticAnchorTime = DateTime.now();

    final state = cubit.state;
    if (state.isPlaying) {
      await _audioPlayer.seek(position);
    }
  }

  // ── SnackBar helpers ──────────────────────────────────────────────────────────

  void _showTrimSuccessSnackBar(BuildContext context, String filePath) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Trimmed successfully!'),
          backgroundColor: const Color(0xFF1DB954),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.black,
            onPressed: () async {
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'Check out this audio clip!',
              );
            },
          ),
        ),
      );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent.shade400,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              context.read<TrimmerCubit>().clearError();
            },
          ),
        ),
      );
  }

  // ── Output format label ───────────────────────────────────────────────────────

  String _formatLabel(OutputFormat format) {
    switch (format) {
      case OutputFormat.mp3:
        return 'MP3';
      case OutputFormat.aac:
        return 'AAC';
      case OutputFormat.wav:
        return 'WAV';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrimmerCubit, TrimmerState>(
      listener: (context, state) async {
        // ── New file loaded ──────────────────────────────────────────────
        if (state.filePath != null && state.filePath != _prevFilePath) {
          _prevFilePath = state.filePath;
          // preparePlayer is already called inside _loadFile; nothing more
          // needed here. The waveform widget will pick up the controller state.
        }
        _prevFilePath = state.filePath;

        // ── Playback toggle ──────────────────────────────────────────────
        if (state.isPlaying != _prevIsPlaying) {
          _prevIsPlaying = state.isPlaying;
          if (state.isPlaying) {
            await _startPlayback(state);
          } else {
            await _stopPlayback();
          }
        }

        // ── Trim success ─────────────────────────────────────────────────
        if (state.trimSuccess && !_prevTrimSuccess) {
          _prevTrimSuccess = state.trimSuccess;
          if (state.savedFilePath != null && mounted) {
            _showTrimSuccessSnackBar(context, state.savedFilePath!);
          }
        }
        if (!state.trimSuccess) _prevTrimSuccess = false;

        // ── Error ────────────────────────────────────────────────────────
        if (state.errorMessage != null &&
            state.errorMessage != _prevErrorMessage) {
          _prevErrorMessage = state.errorMessage;
          if (mounted) _showErrorSnackBar(context, state.errorMessage!);
        }
        if (state.errorMessage == null) _prevErrorMessage = null;
      },
      child: BlocBuilder<TrimmerCubit, TrimmerState>(
        buildWhen: (prev, curr) {
          // PlaybackBar has its own BlocBuilder for playhead updates; avoid
          // rebuilding the whole screen on every playback tick.
          return prev.filePath != curr.filePath ||
              prev.fileName != curr.fileName ||
              prev.totalDuration != curr.totalDuration ||
              prev.startDuration != curr.startDuration ||
              prev.endDuration != curr.endDuration ||
              prev.isPlaying != curr.isPlaying ||
              prev.isTrimming != curr.isTrimming ||
              prev.trimSuccess != curr.trimSuccess ||
              prev.outputFormat != curr.outputFormat ||
              prev.errorMessage != curr.errorMessage ||
              prev.savedFilePath != curr.savedFilePath ||
              prev.isLoading != curr.isLoading;
        },
        builder: (context, state) {
          final cubit = context.read<TrimmerCubit>();
          final bool hasFile = state.filePath != null;

          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),

            // ── AppBar ──────────────────────────────────────────────────
            appBar: AppBar(
              backgroundColor: const Color(0xFF121212),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(
                state.fileName ?? 'AudioTrimr',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Format selector chip
                if (hasFile)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ActionChip(
                      label: Text(
                        _formatLabel(state.outputFormat),
                        style: const TextStyle(
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1DB954).withOpacity(0.12),
                      side: const BorderSide(
                        color: Color(0xFF1DB954),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () => showFormatBottomSheet(context),
                    ),
                  ),
              ],
              // Trim progress indicator
              bottom: state.isTrimming
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(3),
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF2A2A2A),
                        color: Color(0xFF1DB954),
                        minHeight: 3,
                      ),
                    )
                  : null,
            ),

            // ── Body ────────────────────────────────────────────────────
            body: hasFile ? _buildEditorBody(context, state) : _buildEmptyBody(context),

            // ── Bottom App Bar ───────────────────────────────────────────
            bottomNavigationBar: hasFile
                ? _buildBottomBar(context, state, cubit)
                : null,
          );
        },
      ),
    );
  }

  // ── Empty (no file) body ──────────────────────────────────────────────────────

  Widget _buildEmptyBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1DB954).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.audio_file_rounded,
                size: 48,
                color: Color(0xFF1DB954),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pick an audio file',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an MP3, AAC, WAV, or other audio file\nto start trimming.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickFile(context),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Editor body ───────────────────────────────────────────────────────────────

  Widget _buildEditorBody(BuildContext context, TrimmerState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // ── Waveform ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: WaveformWidget(playerController: _playerController),
          ),

          const SizedBox(height: 8),

          // Total file duration & loading indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${formatDuration(state.totalDuration)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (state.isLoading)
                  Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Loading…',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E1E1E), height: 1),
          const SizedBox(height: 4),

          // ── Trim controls (range slider) ──────────────────────────────
          const TrimControls(),

          const Divider(color: Color(0xFF1E1E1E), height: 1),
          const SizedBox(height: 4),

          // ── Playback seek bar ─────────────────────────────────────────
          PlaybackBar(
            onSeek: _onSeek,
            audioPlayer: _audioPlayer,
            isPlaying: state.isPlaying,
          ),
        ],
      ),
    );
  }

  // ── Bottom app bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(
      BuildContext context, TrimmerState state, TrimmerCubit cubit) {
    return BottomAppBar(
      color: const Color(0xFF121212),
      elevation: 8,
      height: 72,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ── Pick new file ────────────────────────────────────────────
            IconButton(
              icon: const Icon(Icons.folder_open_rounded),
              color: Colors.white70,
              tooltip: 'Pick new file',
              onPressed: () => _pickFile(context),
            ),

            const Spacer(),

            // ── Play / Pause FAB ─────────────────────────────────────────
            FloatingActionButton(
              onPressed: state.filePath != null && !state.isTrimming
                  ? () => cubit.togglePlayback()
                  : null,
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
              elevation: 4,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(state.isPlaying),
                  size: 32,
                ),
              ),
            ),

            const Spacer(),

            // ── Trim button ──────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: state.filePath != null && !state.isTrimming
                  ? () => cubit.trimAudio()
                  : null,
              icon: state.isTrimming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1DB954),
                      ),
                    )
                  : const Icon(Icons.content_cut_rounded, size: 18),
              label: Text(state.isTrimming ? 'Trimming…' : 'Trim'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1DB954),
                side: const BorderSide(color: Color(0xFF1DB954)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
