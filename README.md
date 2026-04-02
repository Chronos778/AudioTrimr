# TRIMR

TRIMR is a compact audio trimmer for Android and iOS. It is built as a mobile-first editing workspace: import a track, inspect the waveform, set in/out points, preview the cut, and export the result with optional fades and preset-based output settings.

## What It Does

- Import common audio formats including MP3, WAV, M4A, AAC, OGG, and FLAC.
- Trim with draggable start/end handles and an animated waveform.
- Zoom the waveform, loop playback, and undo or redo edit changes.
- Apply fade in and fade out on export.
- Pick export presets for balanced, low-bitrate, high-bitrate, or WAV master output.
- Share the exported file from the app.
- Handle runtime media permissions on Android.

## Project Layout

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme.dart
├── core/
│   ├── audio/
│   │   └── audio_service.dart
│   ├── permissions/
│   │   └── permission_service.dart
│   └── utils/
│       └── format_utils.dart
└── features/
    └── trimmer/
        ├── providers/
        │   └── trimmer_provider.dart
        ├── screen/
        │   └── trimmer_view.dart
        └── widgets/
            ├── export_panel.dart
            ├── file_import_zone.dart
            ├── transport_controls.dart
            ├── trim_handle.dart
            ├── trim_info_bar.dart
            └── waveform_painter.dart
```

## Tech Stack

- Flutter / Dart
- Riverpod for editor state
- `just_audio` for playback
- `ffmpeg_kit_flutter_new` for trim and export processing
- `permission_handler` for runtime permissions
- `share_plus` for sharing exports
- `flutter_animate` for motion

## Run It

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter test
flutter build apk --split-per-abi --release
flutter build ios --release
```

## Release Check

Before shipping, confirm the following:

- Android release signing is configured in `android/app/build.gradle.kts`.
- The app exports correctly on a real device for the target formats.
- Media permissions still work on a clean install.
- Screenshots and store metadata are prepared.
- The final APK or IPA is generated from a release build, not a debug build.

## License

MIT
