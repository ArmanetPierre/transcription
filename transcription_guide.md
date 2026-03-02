# Guide Technique - Transcription + Diarization sur Apple Silicon

## Vue d'ensemble du pipeline

Le processus se fait en 3 etapes :

```
Audio (m4a, wav, mp3...)
    |
    v
[1. TRANSCRIPTION] --> texte brut avec timestamps
    |                   (Whisper)
    v
[2. ALIGNEMENT] ------> timestamps precis mot par mot
    |                   (wav2vec2)
    v
[3. DIARIZATION] -----> identification des speakers
                        (pyannote)
```

---

## Etape 1 : Transcription (Speech-to-Text)

**But** : convertir l'audio en texte avec des timestamps par segment.

### Options disponibles

| Outil | Backend | Support MPS/Metal | Vitesse M3 Pro | Langue FR |
|-------|---------|-------------------|----------------|-----------|
| **whisper.cpp** | C++ / Metal natif | Oui (GPU Metal) | Tres rapide | Oui |
| **MLX Whisper** | MLX (Apple) | Oui (GPU MLX) | Tres rapide | Oui |
| **faster-whisper** | CTranslate2 | Non (CPU only) | Moyen | Oui |
| **openai-whisper** | PyTorch | MPS partiel | Lent | Oui |

### Recommandation : whisper.cpp

- Implementation C++ du modele Whisper d'OpenAI
- Utilise **Metal** (GPU Apple Silicon) nativement, sans PyTorch
- Modeles disponibles : tiny, base, small, medium, large-v3
- large-v3 = meilleure qualite, ~5-10 min pour 1h d'audio sur M3 Pro
- Bindings Swift disponibles (whisper.swiftui, WhisperKit)

```bash
# Installation
brew install whisper-cpp

# Telecharger un modele (large-v3 pour la meilleure qualite)
# Les modeles sont au format GGML (~3 Go pour large-v3)

# Utilisation
whisper-cpp -m models/ggml-large-v3.bin -l fr -f audio.wav --output-json
```

### Alternative Swift : WhisperKit

- Framework Swift natif par Argmax (optimise Apple Silicon)
- Utilise CoreML, ideal pour une app Mac native
- https://github.com/argmaxinc/WhisperKit

```swift
import WhisperKit

let whisper = try await WhisperKit(model: "large-v3")
let results = try await whisper.transcribe(audioPath: "audio.m4a")
```

---

## Etape 2 : Alignement (optionnel si diarization)

**But** : recaler les timestamps au niveau de chaque mot (pas juste par segment).
Necessaire pour attribuer precisement chaque mot a un speaker.

- Modele utilise : **wav2vec2** (specifique par langue)
- Modele FR : `jonatasgrosman/wav2vec2-large-xlsr-53-french`
- Tourne via PyTorch, **supporte MPS**

```python
import whisperx
model_a, metadata = whisperx.load_align_model(language_code="fr", device="mps")
result = whisperx.align(segments, model_a, metadata, audio, device="mps")
```

---

## Etape 3 : Diarization (Speaker Identification)

**But** : determiner "qui parle quand" dans l'audio.

### pyannote-audio

- Modele de reference pour la diarization
- **Licence MIT** (libre, usage commercial OK)
- Modele heberge sur HuggingFace (gated : il faut accepter la licence pour telecharger)
- L'acceptation sert juste a collecter des stats utilisateurs, aucune restriction d'usage
- **Supporte MPS** (PyTorch standard)

```python
from pyannote.audio import Pipeline

pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1",
    use_auth_token="hf_xxx"  # token HuggingFace pour telecharger le modele
)

# Utiliser le GPU Apple Silicon
import torch
pipeline.to(torch.device("mps"))

# Lancer la diarization
diarization = pipeline("audio.wav")

# Resultat : segments avec labels speakers
for turn, _, speaker in diarization.itertracks(yield_label=True):
    print(f"{turn.start:.1f} --> {turn.end:.1f} : {speaker}")
```

### HuggingFace Token

- Creer un compte sur https://huggingface.co
- Generer un token : Settings > Access Tokens
- Accepter la licence du modele : https://huggingface.co/pyannote/speaker-diarization-3.1
- Le token sert **uniquement au telechargement**, l'execution est 100% locale
- Le modele est cache dans `~/.cache/huggingface/` apres le premier telechargement

---

## Performance sur M3 Pro

| Etape | CPU | MPS/Metal | Gain estime |
|-------|-----|-----------|-------------|
| Transcription (whisper.cpp Metal) | ~30 min/h | ~5-10 min/h | 3-6x |
| Alignement (wav2vec2) | ~5 min/h | ~1-2 min/h | 3-5x |
| Diarization (pyannote) | ~45 min/h | ~5-10 min/h | 5-10x |
| **Total** | **~80 min/h** | **~10-20 min/h** | **~5x** |

### Configuration MPS (PyTorch)

```python
import torch

# Verifier la disponibilite de MPS
if torch.backends.mps.is_available():
    device = torch.device("mps")
else:
    device = torch.device("cpu")
```

### Attention MPS

- Certaines operations PyTorch ne sont pas encore implementees sur MPS
- En cas d'erreur, fallback sur CPU pour l'operation concernee :
  ```python
  import os
  os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
  ```
- Sur M3 Pro c'est generalement stable, les problemes sont surtout sur les anciens M1

---

## Architecture pour une app Mac

### Option 1 : App Swift native

```
SwiftUI App
    |
    +-- WhisperKit (transcription, natif Swift/CoreML)
    |
    +-- pyannote via Python bridge (diarization)
    |   (PythonKit ou subprocess vers un script Python)
    |
    +-- UI : import audio, progress, editeur de transcription
```

### Option 2 : App Electron/Tauri + Python backend

```
Frontend (React/Tauri)
    |
    +-- Backend Python (FastAPI ou subprocess)
        |
        +-- whisper.cpp (transcription)
        +-- pyannote (diarization)
```

### Option 3 : Tout Python + UI native

```
Python app (PyQt / rumps pour menu bar)
    |
    +-- whisper.cpp (via bindings python : pywhispercpp)
    +-- pyannote (diarization)
    +-- export : JSON, SRT, TXT, MD
```

---

## Formats de sortie courants

| Format | Usage |
|--------|-------|
| **SRT** | Sous-titres video (compatible VLC, Premiere, etc.) |
| **JSON** | Traitement programmatique, stockage structure |
| **TXT** | Lecture humaine avec speakers et timestamps |
| **MD** | Compte rendu formate |

---

## Dependances Python (si backend Python)

```txt
# Diarization
pyannote.audio>=3.1
torch>=2.0

# Transcription (si pas whisper.cpp)
faster-whisper>=1.0
# ou
whisperx>=3.8

# Alignement
transformers

# Audio
soundfile
librosa
```

---

## Ressources

- whisper.cpp : https://github.com/ggerganov/whisper.cpp
- WhisperKit (Swift) : https://github.com/argmaxinc/WhisperKit
- MLX Whisper : https://github.com/ml-explore/mlx-examples/tree/main/whisper
- pyannote-audio : https://github.com/pyannote/pyannote-audio
- faster-whisper : https://github.com/SYSTRAN/faster-whisper
- whisperx : https://github.com/m-bain/whisperX
