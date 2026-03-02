#!/usr/bin/env python3
"""
Transcription + diarisation audio en local.
Utilise mlx-whisper (GPU Apple Silicon) + pyannote (diarisation).
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time

# Activer le fallback CPU pour les opérations MPS non supportées
os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"

import mlx_whisper
import numpy as np
import soundfile as sf
import torch
from pyannote.audio import Pipeline as PyannotePipeline


def get_device():
    """Détecte le meilleur device PyTorch : MPS (Apple Silicon GPU) > CPU."""
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def format_timestamp(seconds):
    """Convertit des secondes en format HH:MM:SS."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h:02d}:{m:02d}:{s:02d}"


def format_srt_timestamp(seconds):
    """Convertit des secondes en format SRT (HH:MM:SS,mmm)."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds % 1) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def assign_speakers_to_segments(segments, diarization):
    """Attribue un speaker à chaque segment de transcription basé sur la diarisation."""
    for seg in segments:
        seg_start = seg["start"]
        seg_end = seg["end"]
        # Trouver le speaker qui parle le plus pendant ce segment
        speaker_durations = {}
        for turn, _, speaker in diarization.itertracks(yield_label=True):
            # Calculer le chevauchement entre le segment et le turn
            overlap_start = max(seg_start, turn.start)
            overlap_end = min(seg_end, turn.end)
            overlap = max(0, overlap_end - overlap_start)
            if overlap > 0:
                speaker_durations[speaker] = speaker_durations.get(speaker, 0) + overlap
        if speaker_durations:
            seg["speaker"] = max(speaker_durations, key=speaker_durations.get)
        else:
            seg["speaker"] = "Inconnu"
    return segments


def output_txt(segments, output_path):
    """Format TXT avec speakers et timestamps."""
    with open(output_path, "w", encoding="utf-8") as f:
        for seg in segments:
            speaker = seg.get("speaker", "Inconnu")
            start = format_timestamp(seg["start"])
            end = format_timestamp(seg["end"])
            text = seg["text"].strip()
            f.write(f"[{start} - {end}] {speaker} : {text}\n")
    print(f"Sauvegardé : {output_path}")


def output_json(segments, output_path):
    """Format JSON structuré."""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"segments": segments}, f, ensure_ascii=False, indent=2, default=str)
    print(f"Sauvegardé : {output_path}")


def output_srt(segments, output_path):
    """Format SRT avec speaker en préfixe."""
    with open(output_path, "w", encoding="utf-8") as f:
        for i, seg in enumerate(segments, 1):
            speaker = seg.get("speaker", "Inconnu")
            start = format_srt_timestamp(seg["start"])
            end = format_srt_timestamp(seg["end"])
            text = seg["text"].strip()
            f.write(f"{i}\n{start} --> {end}\n[{speaker}] {text}\n\n")
    print(f"Sauvegardé : {output_path}")


def output_md(segments, output_path):
    """Format Markdown : compte-rendu par speaker."""
    groups = []
    current_speaker = None
    current_texts = []
    current_start = None

    for seg in segments:
        speaker = seg.get("speaker", "Inconnu")
        if speaker != current_speaker:
            if current_speaker is not None:
                groups.append({
                    "speaker": current_speaker,
                    "start": current_start,
                    "texts": current_texts,
                })
            current_speaker = speaker
            current_texts = [seg["text"].strip()]
            current_start = seg["start"]
        else:
            current_texts.append(seg["text"].strip())

    if current_speaker is not None:
        groups.append({
            "speaker": current_speaker,
            "start": current_start,
            "texts": current_texts,
        })

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("# Transcription\n\n")
        for group in groups:
            ts = format_timestamp(group["start"])
            f.write(f"**{group['speaker']}** _{ts}_\n\n")
            f.write(" ".join(group["texts"]) + "\n\n")
    print(f"Sauvegardé : {output_path}")


OUTPUT_FORMATS = {
    "txt": output_txt,
    "json": output_json,
    "srt": output_srt,
    "md": output_md,
}

# Mapping des noms de modèles vers les IDs HuggingFace pour mlx-whisper
MLX_MODELS = {
    "tiny": "mlx-community/whisper-tiny-mlx",
    "base": "mlx-community/whisper-base-mlx",
    "small": "mlx-community/whisper-small-mlx",
    "medium": "mlx-community/whisper-medium-mlx",
    "large-v3": "mlx-community/whisper-large-v3-mlx",
    "large-v3-turbo": "mlx-community/whisper-large-v3-turbo",
}


def main():
    parser = argparse.ArgumentParser(
        description="Transcription + diarisation audio (local, GPU Apple Silicon)"
    )
    parser.add_argument("audio", help="Chemin du fichier audio")
    parser.add_argument(
        "--language", "-l", default=None,
        help="Langue de l'audio (fr, en, ...). Auto-détection si non spécifié."
    )
    parser.add_argument(
        "--model", "-m", default="large-v3-turbo",
        choices=MLX_MODELS.keys(),
        help="Modèle Whisper (défaut: large-v3-turbo)"
    )
    parser.add_argument(
        "--num-speakers", "-n", type=int, default=None,
        help="Nombre de speakers (optionnel, détection auto sinon)"
    )
    parser.add_argument(
        "--min-speakers", type=int, default=None,
        help="Nombre minimum de speakers"
    )
    parser.add_argument(
        "--max-speakers", type=int, default=None,
        help="Nombre maximum de speakers"
    )
    parser.add_argument(
        "--output", "-o", default="txt",
        choices=OUTPUT_FORMATS.keys(),
        help="Format de sortie (txt, json, srt, md). Défaut: txt"
    )
    parser.add_argument(
        "--output-dir", default=None,
        help="Répertoire de sortie. Défaut: même répertoire que le fichier audio"
    )
    parser.add_argument(
        "--hf-token", default=None,
        help="Token HuggingFace (ou variable HF_TOKEN)"
    )
    parser.add_argument(
        "--no-diarize", action="store_true",
        help="Désactiver la diarisation (transcription seule)"
    )
    args = parser.parse_args()

    # Vérifier que le fichier existe
    if not os.path.isfile(args.audio):
        print(f"Erreur : fichier introuvable : {args.audio}", file=sys.stderr)
        sys.exit(1)

    torch_device = get_device()
    model_id = MLX_MODELS[args.model]

    print(f"=== Transcription + Diarisation ===")
    print(f"Fichier       : {args.audio}")
    print(f"Modèle        : {args.model} ({model_id})")
    print(f"Langue        : {args.language or 'auto'}")
    print(f"Device MLX    : GPU Apple Silicon (Metal)")
    print(f"Device PyTorch: {torch_device} (diarisation)")
    print(f"Format sortie : {args.output}")
    print()

    # === Étape 1 : Transcription (mlx-whisper, GPU) ===
    print("[1/3] Transcription en cours (mlx-whisper, GPU)...")
    t0 = time.time()

    transcribe_kwargs = {"path_or_hf_repo": model_id, "verbose": False}
    if args.language:
        transcribe_kwargs["language"] = args.language

    result = mlx_whisper.transcribe(args.audio, **transcribe_kwargs)

    detected_language = result.get("language", args.language or "?")
    segments = result["segments"]

    # Filtrer les hallucinations (segments avec start == end ou répétés à la fin)
    filtered = []
    for seg in segments:
        if seg["start"] >= seg["end"]:
            continue
        text = seg["text"].strip()
        if not text or len(text) <= 1:
            continue
        filtered.append(seg)
    if len(filtered) < len(segments):
        print(f"       {len(segments) - len(filtered)} segments hallucinés filtrés")
    segments = filtered

    t1 = time.time()
    print(f"       Langue détectée : {detected_language}")
    print(f"       Transcription terminée en {t1 - t0:.1f}s")
    print(f"       {len(segments)} segments trouvés")

    # === Étape 2 : Diarisation (pyannote, GPU via MPS) ===
    if not args.no_diarize:
        hf_token = args.hf_token or os.environ.get("HF_TOKEN") or None

        print("[2/3] Diarisation (pyannote, GPU via MPS)...")
        t2 = time.time()

        # Charger depuis le cache local si pas de token HF
        if hf_token is None:
            os.environ["HF_HUB_OFFLINE"] = "1"

        try:
            pipeline = PyannotePipeline.from_pretrained(
                "pyannote/speaker-diarization-3.1",
                token=hf_token,
            )
        except Exception:
            if hf_token is None:
                print(
                    "\nErreur : modèles pyannote non trouvés en cache local.",
                    file=sys.stderr,
                )
                print(
                    "Lancez une première fois avec --hf-token TOKEN pour les télécharger.",
                    file=sys.stderr,
                )
                print(
                    "Ensuite le token ne sera plus nécessaire.",
                    file=sys.stderr,
                )
                sys.exit(1)
            else:
                raise

        pipeline.to(torch.device(torch_device))

        diarize_kwargs = {}
        if args.num_speakers is not None:
            diarize_kwargs["num_speakers"] = args.num_speakers
        if args.min_speakers is not None:
            diarize_kwargs["min_speakers"] = args.min_speakers
        if args.max_speakers is not None:
            diarize_kwargs["max_speakers"] = args.max_speakers

        # Charger l'audio en mémoire (contourne le bug torchcodec/FFmpeg 8)
        # soundfile ne supporte pas m4a/aac, on convertit via ffmpeg si nécessaire
        audio_path = args.audio
        tmp_wav = None
        try:
            waveform_np, sample_rate = sf.read(audio_path, dtype="float32")
        except Exception:
            # Format non supporté par soundfile, conversion via ffmpeg
            print("       Conversion audio via ffmpeg...")
            tmp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
            tmp_wav.close()
            subprocess.run(
                ["ffmpeg", "-i", audio_path, "-ar", "16000", "-ac", "1",
                 "-y", tmp_wav.name],
                capture_output=True, check=True,
            )
            waveform_np, sample_rate = sf.read(tmp_wav.name, dtype="float32")

        if waveform_np.ndim == 1:
            waveform_np = waveform_np[np.newaxis, :]  # (1, time)
        else:
            waveform_np = waveform_np.T  # (channels, time)
        audio_dict = {
            "waveform": torch.from_numpy(waveform_np),
            "sample_rate": sample_rate,
        }
        diarize_output = pipeline(audio_dict, **diarize_kwargs)
        if tmp_wav is not None:
            os.unlink(tmp_wav.name)
        t3 = time.time()

        # Extraire l'annotation (pyannote 4.x retourne DiarizeOutput)
        if hasattr(diarize_output, "speaker_diarization"):
            diarization = diarize_output.speaker_diarization
        else:
            diarization = diarize_output

        # Attribuer les speakers aux segments
        print("[3/3] Attribution des speakers aux segments...")
        segments = assign_speakers_to_segments(segments, diarization)

        speakers = set(seg.get("speaker", "Inconnu") for seg in segments)
        print(f"       {len(speakers)} speakers identifiés : {', '.join(sorted(speakers))}")
        print(f"       Diarisation terminée en {t3 - t2:.1f}s")
    else:
        print("[2/3] Diarisation désactivée")
        print("[3/3] -")

    # === Sortie ===
    output_dir = args.output_dir or os.path.dirname(os.path.abspath(args.audio))
    base_name = os.path.splitext(os.path.basename(args.audio))[0]
    output_path = os.path.join(output_dir, f"{base_name}.{args.output}")

    OUTPUT_FORMATS[args.output](segments, output_path)

    total_time = time.time() - t0
    print(f"\nTerminé en {total_time:.1f}s")


if __name__ == "__main__":
    main()
