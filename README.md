# 🎬 MyPlayer Pro

A minimal, polished desktop media player for **Windows** built with Flutter, Riverpod, and `media_kit` (libmpv). Designed with a focus on simplicity, restrained dark aesthetics, responsive playback controls, and smooth keyboard navigation.

---

## ✨ Features

- **Floating Minimalist Playbar**: An IINA-inspired dark glass capsule floating subtly above the video. Auto-hides along with the mouse cursor after 3 seconds of inactivity.
- **Predictable & Coalesced Seeking**:
  - Dedicated seek backward and forward buttons separate from playlist navigation.
  - Left/Right keyboard seeking with intelligent 90ms coalescing—rapid key presses accumulate into a single smooth seek without queuing choppy jumps.
  - 60fps scrub feedback on the seek bar, dispatching the seek command only when the slider thumb is released.
- **Bidirectional Volume & Instant Mute**:
  - Full synchronization between keyboard controls (<kbd>↑</kbd>/<kbd>↓</kbd>), the playbar volume slider, and on-screen indicators.
  - Toggle mute with <kbd>M</kbd> or by clicking the volume icon, with previous volume memory.
- **Clean Shutdown (Zero Audio Lag)**: Intercepts the native Windows close event to instantaneously cut off hardware audio (0ms delay), preventing trailing audio when exiting.
- **On-Screen Display (OSD) HUD**: An unobtrusive, centered dark pill that displays immediate feedback for seeking (`±5s [01:23 / 05:40]`), volume levels with progress bars, playback rate, and loaded track names.
- **Customizable Shortcuts & Conflict Prevention**:
  - Customize seek step (2s–60s) and volume step (1%–20%).
  - Rebind keys with validation that prevents duplicate assignments and protects reserved system keys (<kbd>Space</kbd>, <kbd>F</kbd>, <kbd>M</kbd>, <kbd>Esc</kbd>).
  - Persists all settings between app launches via `SharedPreferences`.
- **Audio Equalizer & Night Mode**:
  - 5-band graphic equalizer with presets (Flat, Rock, Pop, Classical, Voice, Bass Boost) and preamp control.
  - Night Mode dynamic compression (boosts quiet dialogue and levels loud action scenes).
  - Sub-second audio sync delay adjustment.
- **Subtitle Framing & Sync**:
  - Adjust vertical position (including moving subtitles into the bottom letterbox area).
  - Custom font size scaling, background box opacity, and sub-millisecond delay sync.
  - Supports embedded subtitles as well as loading external `.srt`, `.ass`, `.ssa`, and `.vtt` files.
- **Streamlined Context Menu**:
  - Right-click anywhere for quick access to tracks, filters, aspect ratios, and media properties.
  - Guarantees **Automatic** and **Off (Disable)** options for both audio and subtitle streams.
  - Automatically vanishes when clicking anywhere outside the menu.
- **Drag-and-Drop & Playlists**:
  - Drop single media files or multiple tracks directly into the window to play or queue.
  - Side playlist panel with item counters, drag-to-reorder, and individual track removal.

---

## ⌨️ Keyboard Shortcuts

| Action | Shortcut |
| :--- | :--- |
| **Play / Pause** | <kbd>Space</kbd> |
| **Seek Backward** | <kbd>←</kbd> (Default 5s, customizable) |
| **Seek Forward** | <kbd>→</kbd> (Default 5s, customizable) |
| **Volume Up** | <kbd>↑</kbd> (Default 5%, customizable) |
| **Volume Down** | <kbd>↓</kbd> (Default 5%, customizable) |
| **Toggle Mute** | <kbd>M</kbd> |
| **Toggle Fullscreen** | <kbd>F</kbd> / <kbd>F11</kbd> / Double-Click Video |
| **Exit Fullscreen / Close Drawer** | <kbd>Esc</kbd> |
| **Open Media File** | <kbd>Ctrl</kbd> + <kbd>O</kbd> |
| **Context Menu** | Right-Click |
| **Exit Application** | <kbd>Alt</kbd> + <kbd>F4</kbd> |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install/windows) (>=3.4.0 <4.0.0)
- Visual Studio 2022 with **Desktop development with C++** workload installed

### Run in Development Mode

```bash
# Clone the repository
git clone https://github.com/Ysh204/MyPlayer.git
cd MyPlayer

# Fetch dependencies
flutter pub get

# Run on Windows desktop
flutter run -d windows
```

### Build Portable Release Executable

```bash
flutter build windows
```

The compiled release will be generated at:
```
build/windows/x64/runner/Release/
```

To run directly:
```powershell
.\build\windows\x64\runner\Release\my_player.exe
```

---

## 🏗️ Architecture

```
lib/
├── app.dart                   # MaterialApp configuration and global dark theme
├── main.dart                  # Window initialization, size constraints, and close prevention
├── core/
│   ├── theme/app_theme.dart   # Refined dark theme, desktop sliders, and tooltip styling
│   └── utils/time_formatter.dart # Tabular duration formatting
├── data/models/               # State models for Equalizer, Presets, and Subtitles
├── features/
│   ├── audio/                 # Equalizer panel, audio DSP filters, and presets
│   ├── player/
│   │   ├── providers/         # PlaybackNotifier, OSD state, and shortcut preference persistence
│   │   ├── screens/           # PlayerScreen, floating HUD controls, and empty state
│   │   └── widgets/           # Track picker, OSD overlay
│   ├── playlist/              # Playlist drawer with reordering and queue management
│   ├── settings/              # Shortcut re-binding and playback settings dialog
│   └── subtitles/             # Subtitle framing, styling, and sync controls
└── services/
    ├── player_service.dart    # Central abstraction layer for libmpv / media_kit
    ├── mpv_properties.dart    # Low-level libmpv native property bridge
    ├── subtitle_service.dart  # Subtitle track and framing service
    └── audio_filter_builder.dart # lavfi audio filter graph generation
```

---

## 🧪 Testing

Run the automated test suite covering duration formatting, track labeling, OSD notifications, and shortcut validation:

```bash
flutter test
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
