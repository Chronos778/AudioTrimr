# TRIMR

**Precision audio trimmer for Android & iOS.**

Pick any audio file, visualize its waveform, set trim points with draggable handles, preview the segment in real-time, and export to your format of choice — all from a single, distraction-free screen.

---

## Features

- **Multi-format import** — MP3, WAV, M4A, AAC, OGG, FLAC
- **Real-time waveform** — Amplitude-mapped bars with trim region highlighting and animated playhead
- **Draggable trim handles** — Haptic feedback, snapping, sub-second precision
- **Live preview** — Play only the selected segment before committing
- **Multi-format export** — Trim to MP3, WAV, AAC, or M4A via FFmpeg
- **File metadata** — Duration, format, file size, bitrate at a glance
- **Share** — Export and share trimmed files directly from the app
- **Permissions** — Android 13+ granular media permissions with rationale dialogs

## Screenshots

> *Install the debug APK and run on a device to see the full Dark Precision Instrument UI.*

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x / Dart 3.x |
| State | Riverpod (`StateNotifier`) |
| Playback | `just_audio` |
| Processing | `ffmpeg_kit_flutter_new` |
| Permissions | `permission_handler` |
| Sharing | `share_plus` |
| Typography | Google Fonts (IBM Plex Mono + DM Sans) |
| Animations | `flutter_animate` |

## Architecture

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # MaterialApp + routing
│   └── theme.dart                     # Design tokens & typography
├── core/
│   ├── audio/
│   │   └── audio_service.dart         # Playback, waveform extraction, FFmpeg trim
│   ├── permissions/
│   │   └── permission_service.dart    # Runtime permission handling
│   └── utils/
│       └── format_utils.dart          # Duration, file size, bitrate formatters
└── features/
    └── trimmer/
        ├── providers/
        │   └── trimmer_provider.dart  # Riverpod state management
        ├── screen/
        │   └── trimmer_screen.dart    # Main screen layout
        └── widgets/
            ├── file_import_zone.dart  # File picker UI
            ├── waveform_painter.dart  # Custom waveform renderer
            ├── trim_handle.dart       # Draggable start/end handles
            ├── playback_controls.dart # Play/pause, seek, time display
            ├── trim_info_bar.dart     # Trim metadata display
            └── export_panel.dart      # Format selector + export + share
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x+ ([install](https://docs.flutter.dev/get-started/install))
- Android SDK with API 24+ (for FFmpeg)
- Xcode 15+ (for iOS builds)

### Setup

```bash
# Clone
git clone <repo-url>
cd trimr

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

> **Note:** The first build takes longer than usual — `ffmpeg_kit_flutter_new` downloads ~200 MB of native binaries.

### Build

```bash
# Debug APK (all architectures, ~360 MB)
flutter build apk --debug

# Release APK (split per architecture, ~50-80 MB each)
flutter build apk --split-per-abi --release

# iOS
flutter build ios --release
```

## Platform Requirements

| Platform | Min Version | Notes |
|----------|------------|-------|
| Android | API 24 (Nougat 7.0) | Required by FFmpeg Kit |
| iOS | 12.0 | Default Flutter minimum |

## Design System

The app uses a **Dark Precision Instrument** aesthetic:

| Token | Value | Usage |
|-------|-------|-------|
| `bgPrimary` | `#0A0A0C` | Main background |
| `bgSurface` | `#111114` | Cards & panels |
| `accentElec` | `#00E5FF` | Primary accent (cyan) |
| `accentGreen` | `#00E676` | Success states |
| `accentRed` | `#FF1744` | Error states |
| `accentAmber` | `#FFAB00` | Warnings |
| Mono font | IBM Plex Mono | Labels, values, metadata |
| Sans font | DM Sans | Body text, headings |

## License

MIT
