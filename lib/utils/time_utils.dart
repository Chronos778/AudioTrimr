/// Formats [d] as `mm:ss.ms` — e.g., `"01:23.45"`.
///
/// The milliseconds portion is two digits (centiseconds), derived by
/// taking `d.milliseconds ~/ 10`.
String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final centiseconds = (d.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds.$centiseconds';
}

/// Formats [d] as `mm:ss` — e.g., `"01:23"`.
String formatDurationShort(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Convenience wrapper: converts milliseconds to a `mm:ss.ms` string.
String msToString(int ms) => formatDuration(Duration(milliseconds: ms));
