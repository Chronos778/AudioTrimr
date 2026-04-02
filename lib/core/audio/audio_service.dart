import 'dart:io';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AudioMetadata {
  final String fileName;
  final String format;
  final Duration duration;
  final int fileSize;
  final int bitrate;
  final String filePath;

  const AudioMetadata({
    required this.fileName,
    required this.format,
    required this.duration,
    required this.fileSize,
    required this.bitrate,
    required this.filePath,
  });
}

class WaveformData {
  final List<double> samples;
  final Duration duration;

  const WaveformData({required this.samples, required this.duration});
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  AudioMetadata? _currentMetadata;

  AudioPlayer get player => _player;
  AudioMetadata? get currentMetadata => _currentMetadata;

  Future<AudioMetadata> loadFile(String filePath) async {
    final file = File(filePath);
    final fileName = p.basename(filePath);
    final format = p.extension(filePath).replaceAll('.', '').toUpperCase();
    final fileSize = await file.length();

    // Get duration and bitrate via ffprobe
    Duration duration = Duration.zero;
    int bitrate = 0;

    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();
      if (info != null) {
        final durationStr = info.getDuration();
        if (durationStr != null) {
          final seconds = double.tryParse(durationStr) ?? 0;
          duration = Duration(milliseconds: (seconds * 1000).round());
        }
        final bitrateStr = info.getBitrate();
        if (bitrateStr != null) {
          bitrate = int.tryParse(bitrateStr) ?? 0;
        }
      }
    } catch (_) {
      // Fallback: use just_audio for duration
    }

    // Also set up audio player
    try {
      final audioDuration = await _player.setFilePath(filePath);
      if (duration == Duration.zero && audioDuration != null) {
        duration = audioDuration;
      }
    } catch (_) {}

    _currentMetadata = AudioMetadata(
      fileName: fileName,
      format: format,
      duration: duration,
      fileSize: fileSize,
      bitrate: bitrate,
      filePath: filePath,
    );

    return _currentMetadata!;
  }

  /// Generate a synthetic waveform from the audio file using ffmpeg
  Future<WaveformData> extractWaveform(String filePath, int sampleCount) async {
    final tempDir = await getTemporaryDirectory();
    final rawFile = '${tempDir.path}/waveform_raw.pcm';

    // Use ffmpeg to convert to raw PCM mono 8kHz for waveform extraction
    final command =
        '-y -i "$filePath" -ac 1 -ar 8000 -f s16le -acodec pcm_s16le "$rawFile"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final file = File(rawFile);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final totalSamples = bytes.length ~/ 2; // 16-bit samples

        if (totalSamples == 0) {
          return WaveformData(
            samples: List.filled(sampleCount, 0.0),
            duration: _currentMetadata?.duration ?? Duration.zero,
          );
        }

        // Read raw PCM data and downsample
        final samplesPerBucket = max(1, totalSamples ~/ sampleCount);
        final waveform = <double>[];

        for (int i = 0; i < sampleCount && i * samplesPerBucket < totalSamples; i++) {
          double maxAmp = 0;
          for (int j = 0; j < samplesPerBucket; j++) {
            final idx = (i * samplesPerBucket + j) * 2;
            if (idx + 1 < bytes.length) {
              // Little-endian signed 16-bit
              int sample = bytes[idx] | (bytes[idx + 1] << 8);
              if (sample >= 32768) sample -= 65536;
              final amp = sample.abs() / 32768.0;
              if (amp > maxAmp) maxAmp = amp;
            }
          }
          waveform.add(maxAmp);
        }

        // Pad if needed
        while (waveform.length < sampleCount) {
          waveform.add(0.0);
        }

        // Clean up
        try {
          await file.delete();
        } catch (_) {}

        return WaveformData(
          samples: waveform,
          duration: _currentMetadata?.duration ?? Duration.zero,
        );
      }
    }

    // Fallback: generate synthetic waveform
    return _generateSyntheticWaveform(sampleCount);
  }

  WaveformData _generateSyntheticWaveform(int sampleCount) {
    final random = Random(42);
    final samples = List.generate(sampleCount, (i) {
      final base = 0.3 + random.nextDouble() * 0.5;
      final envelope = sin(i / sampleCount * pi) * 0.3;
      return (base + envelope).clamp(0.05, 1.0);
    });
    return WaveformData(
      samples: samples,
      duration: _currentMetadata?.duration ?? Duration.zero,
    );
  }

  Future<void> playSegment(Duration start, Duration end) async {
    await _player.setClip(start: start, end: end);
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  /// Trim audio using FFmpeg
  Future<String> trimAudio({
    required String inputPath,
    required Duration start,
    required Duration end,
    required String outputFormat,
    String? exportPreset,
    Duration fadeIn = Duration.zero,
    Duration fadeOut = Duration.zero,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final inputName = p.basenameWithoutExtension(inputPath);
    final ext = outputFormat.toLowerCase();
    final outputPath = '${dir.path}/TRIMR_${inputName}_$timestamp.$ext';

    final startStr = _formatFFmpegTime(start);
    final durationMs = end - start;
    final durationStr = _formatFFmpegTime(durationMs);

    String codec;
    final preset = (exportPreset ?? '').toUpperCase();
    switch (ext) {
      case 'mp3':
        if (preset == 'MP3_LOW') {
          codec = '-codec:a libmp3lame -b:a 96k';
        } else if (preset == 'MP3_HIGH') {
          codec = '-codec:a libmp3lame -b:a 320k';
        } else {
          codec = '-codec:a libmp3lame -q:a 2';
        }
        break;
      case 'aac':
      case 'm4a':
        if (preset == 'AAC_HIGH') {
          codec = '-codec:a aac -b:a 256k';
        } else {
          codec = '-codec:a aac -b:a 192k';
        }
        break;
      case 'wav':
        codec = '-codec:a pcm_s16le';
        break;
      default:
        codec = '-codec:a copy';
    }

    final fadeInSec = fadeIn.inMilliseconds / 1000.0;
    final fadeOutSec = fadeOut.inMilliseconds / 1000.0;
    final clipDurationSec = durationMs.inMilliseconds / 1000.0;

    final filters = <String>[];
    if (fadeInSec > 0) {
      filters.add('afade=t=in:st=0:d=${fadeInSec.toStringAsFixed(3)}');
    }
    if (fadeOutSec > 0 && clipDurationSec > fadeOutSec) {
      final fadeOutStart = clipDurationSec - fadeOutSec;
      filters.add(
          'afade=t=out:st=${fadeOutStart.toStringAsFixed(3)}:d=${fadeOutSec.toStringAsFixed(3)}');
    }

    final filterArg = filters.isNotEmpty ? '-af "${filters.join(',')}"' : '';

    final command =
        '-y -i "$inputPath" -ss $startStr -t $durationStr $codec $filterArg "$outputPath"';

    // Set up progress callback
    if (onProgress != null) {
      final totalMs = durationMs.inMilliseconds.toDouble();
      FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
        final timeMs = stats.getTime().toDouble();
        if (totalMs > 0) {
          final progress = (timeMs / totalMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final outputFile = File(outputPath);
      if (await outputFile.exists()) {
        return outputPath;
      }
      throw Exception('Output file was not created');
    } else {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg failed: ${logs ?? "Unknown error"}');
    }
  }

  String _formatFFmpegTime(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  void dispose() {
    _player.dispose();
  }
}
