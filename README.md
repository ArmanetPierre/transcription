# Voxa

Native macOS application (SwiftUI) for audio transcription with speaker identification (diarization), meeting recording, and automatic meeting report generation.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Python](https://img.shields.io/badge/Python-3.11-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- **Audio transcription** via [mlx-whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) (Apple Silicon GPU optimized)
- **Diarization** (speaker identification) via [pyannote.audio](https://github.com/pyannote/pyannote-audio) 3.1
- **Meeting recording** with system audio + microphone capture (ScreenCaptureKit)
- **Speaker summaries** and **meeting reports** via [Ollama](https://ollama.com) (local LLM)
- **Export** to TXT, JSON, SRT, Markdown
- **Menu bar** with real-time progress tracking
- **Built-in audio player** with segment navigation
- **Multilingual** — adapts to your Mac's language (English / French)
- Drag & drop audio files (m4a, wav, mp3, mp4...)

## Prerequisites

- macOS 14.0+ (Sonoma) on Apple Silicon (M1/M2/M3/M4)
- Python 3.11+ (`brew install python@3.12` or [python.org](https://www.python.org/downloads/))
- A [HuggingFace](https://huggingface.co/settings/tokens) token (for pyannote diarization models)

## Installation

### Quick Install (recommended)

1. Download `Voxa.dmg` from [Releases](https://github.com/ArmanetPierre/Local-Transcription-Mac/releases)
2. Open the DMG and drag **Voxa** to **Applications**
3. Launch Voxa — the setup wizard will guide you through the rest
4. Enter your HuggingFace token when prompted

> **Note:** On first launch, macOS may warn about an unidentified developer. Right-click the app → **Open** to bypass Gatekeeper.

The setup wizard automatically:
- Detects your Python installation
- Creates a dedicated Python environment in `~/Library/Application Support/Voxa/`
- Installs all required ML packages (mlx-whisper, pyannote, torch...)
- This takes 5-10 minutes on first launch depending on your internet connection

> **Note:** You must accept the terms of use for pyannote models on HuggingFace:
> - [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0)
> - [pyannote/speaker-diarization-3.1](https://huggingface.co/pyannote/speaker-diarization-3.1)

### Optional: FFmpeg

FFmpeg improves audio format compatibility. Install with:

```bash
brew install ffmpeg
```

### Optional: Ollama

For AI-powered meeting summaries and speaker synthesis:

1. Install [Ollama](https://ollama.com)
2. Pull a model:

```bash
ollama pull llama3.1:8b
```

## Usage

### Transcription

1. **Drag** an audio file into the import zone (or use File → Import)
2. **Transcription** starts automatically (progress shown in menu bar)
3. Once complete, **identify speakers** by giving them names
4. **Generate summaries** with Ollama (brain icon)
5. **Export** the result in your preferred format

### Meeting Recording

1. Click **Record a meeting** in the menu bar
2. Voxa captures both **system audio** (other participants) and your **microphone**
3. Click **Stop and transcribe** to end recording
4. The recording is automatically transcribed

## Build from source

```bash
git clone https://github.com/ArmanetPierre/Local-Transcription-Mac.git
cd transcription
```

Open `TranscriptionApp/TranscriptionApp.xcodeproj` in Xcode, then Build & Run (Cmd+R).

To build the DMG:

```bash
./scripts/build-dmg.sh
```

## Architecture

```
TranscriptionApp/
└── TranscriptionApp/
    ├── Models/           # SwiftData models, enums
    ├── Services/         # PythonBridge, DependencyManager, OllamaService, RecordingService
    ├── ViewModels/       # TranscriptionListVM, RecordingVM
    ├── Views/            # SwiftUI views (SetupView, Detail, Sidebar, Import, MenuBar)
    ├── Utilities/        # EstimationService, SpeakerColors, TimeFormatting
    └── Resources/        # Bundled Python scripts, localizations
```

### Swift ↔ Python Communication

The Swift app launches the bundled Python script as a subprocess and communicates via a **JSON Lines** protocol on stdout:

```
Swift (PythonBridge) → Process() → transcribe_bridge.py
                     ← stdout (JSON Lines: progress, segments, diarization)
```

### Recording Architecture

Voxa uses a dual-track recording approach to avoid audio echo:
- **System audio** → ScreenCaptureKit → AVAssetWriter (.m4a)
- **Microphone** → AVAudioEngine → AVAudioFile (.wav)
- On stop → AVMutableComposition merges both tracks into a single .m4a file

## CLI Script

The `transcribe.py` script can also be used standalone from the command line:

```bash
# Using the venv created by Voxa
source ~/Library/Application\ Support/Voxa/.venv/bin/activate
python transcribe.py --audio recording.m4a --model large-v3-turbo --hf-token YOUR_TOKEN
```

## License

MIT
