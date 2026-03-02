# Transcription

Application macOS native (SwiftUI) de transcription audio avec identification des interlocuteurs (diarisation) et generation automatique de comptes rendus de reunion.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Python](https://img.shields.io/badge/Python-3.11-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Fonctionnalites

- **Transcription audio** via [mlx-whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) (optimise GPU Apple Silicon)
- **Diarisation** (identification des speakers) via [pyannote.audio](https://github.com/pyannote/pyannote-audio) 3.1
- **Syntheses par speaker** et **comptes rendus de reunion** via [Ollama](https://ollama.com) (LLM local)
- **Export** en TXT, JSON, SRT, Markdown
- **Barre de menu** avec progression en temps reel
- **Lecteur audio** integre avec navigation par segment
- Glisser-deposer de fichiers audio (m4a, wav, mp3, mp4...)

## Prerequis

- macOS 14.0+ (Sonoma) sur Apple Silicon (M1/M2/M3/M4)
- [Xcode](https://developer.apple.com/xcode/) 16+
- Python 3.11+
- [ffmpeg](https://ffmpeg.org/) (`brew install ffmpeg`)
- [Ollama](https://ollama.com) (optionnel, pour les syntheses LLM)
- Un token [HuggingFace](https://huggingface.co/settings/tokens) (pour les modeles pyannote)

## Installation

### 1. Cloner le repo

```bash
git clone https://github.com/VOTRE_USERNAME/transcription.git
cd transcription
```

### 2. Environnement Python

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

> **Note :** Acceptez les conditions d'utilisation des modeles pyannote sur HuggingFace :
> - [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0)
> - [pyannote/speaker-diarization-3.1](https://huggingface.co/pyannote/speaker-diarization-3.1)

### 3. ffmpeg

```bash
brew install ffmpeg
```

### 4. Ollama (optionnel)

```bash
brew install ollama
ollama pull llama3.1:8b
```

### 5. Compiler l'app

Ouvrir `TranscriptionApp/TranscriptionApp.xcodeproj` dans Xcode, puis Build & Run (Cmd+R).

## Configuration

Au premier lancement, ouvrez les **Preferences** (Cmd+,) pour configurer :

| Parametre | Description |
|---|---|
| **Token HuggingFace** | Requis pour la diarisation (modeles pyannote) |
| **Chemin Python** | Chemin vers le binaire Python du venv (ex: `.venv/bin/python`) |
| **Chemin Script** | Chemin vers `transcribe_bridge.py` |
| **Modele Whisper** | `large-v3-turbo` (recommande), `large-v3`, `medium`, `small`, `base`, `tiny` |
| **Modele Ollama** | `llama3.1:8b` (recommande), `mistral:latest` |

## Utilisation

1. **Glissez** un fichier audio dans la zone d'import
2. La **transcription** demarre automatiquement (progression dans la barre de menu)
3. Une fois terminee, **identifiez les speakers** en leur donnant des noms
4. **Generez les syntheses** avec Ollama (bouton cerveau)
5. **Exportez** le resultat dans le format souhaite

## Architecture

```
transcription/
├── transcribe_bridge.py      # Script Python (protocole JSON Lines)
├── transcribe.py             # Script CLI standalone
├── requirements.txt          # Dependances Python
└── TranscriptionApp/         # Application SwiftUI
    └── TranscriptionApp/
        ├── Models/           # SwiftData models, enums
        ├── Services/         # PythonBridge, OllamaService, AudioService
        ├── ViewModels/       # TranscriptionListVM, TranscriptionDetailVM
        ├── Views/            # SwiftUI views (Detail, Sidebar, Import, MenuBar)
        └── Utilities/        # EstimationService, SpeakerColors, TimeFormatting
```

### Communication Swift ↔ Python

L'app Swift lance le script Python en subprocess et communique via un protocole **JSON Lines** sur stdout :

```
Swift (PythonBridge) → Process() → transcribe_bridge.py
                     ← stdout (JSON Lines: progress, segments, diarization)
```

## Script CLI

Le script `transcribe.py` peut aussi etre utilise en ligne de commande :

```bash
source .venv/bin/activate
python transcribe.py --audio recording.m4a --model large-v3-turbo --hf-token YOUR_TOKEN
```

## License

MIT
