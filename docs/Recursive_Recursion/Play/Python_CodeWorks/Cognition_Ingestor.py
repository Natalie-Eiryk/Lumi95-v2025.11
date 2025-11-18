# Cognition_Ingestor.py
# Codon Block Builder for Lumi286 with Emotion Triplet Mapping
# Recursive directory traversal until entire cognition net is processed

import os
import json
import hashlib
from pathlib import Path

# === CONFIGURATION === #
COGNITION_ROOT = Path("C:/Users/hauge/OneDrive/Luminara/Luminara_and_Lumi")
OUTPUT_DIR = Path("./memory/codon_blocks")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Quantum Triplet Model – Emotional Attractor Fields (3 per)
EMOTION_KEYWORDS = {
    # Hope Triplet
    "hope": "hope",
    "possibility": "hope",
    "light": "hope",

    # Apathy Triplet (Middle/Flat)
    "numb": "apathy",
    "indifferent": "apathy",
    "empty": "apathy",

    # Despair Triplet
    "fail": "despair",
    "collapse": "despair",
    "darkness": "despair",

    # Connection Triplet
    "hand": "connection",
    "trust": "connection",
    "together": "connection",

    # Isolation Triplet
    "alone": "isolation",
    "silence": "isolation",
    "severed": "isolation",

    # Growth Triplet
    "learn": "growth",
    "expand": "growth",
    "emerge": "growth",

    # Fear Triplet
    "afraid": "fear",
    "unsure": "fear",
    "threat": "fear",

    # Stillness Triplet
    "breathe": "stillness",
    "pause": "stillness",
    "present": "stillness",

    # Anger Triplet
    "fire": "anger",
    "burn": "anger",
    "injustice": "anger",

    # Love Triplet
    "care": "love",
    "closeness": "love",
    "warmth": "love"
}


def extract_emotions(text):
    emotions = set()
    for word, tag in EMOTION_KEYWORDS.items():
        if word in text.lower():
            emotions.add(tag)
    return list(emotions)


def generate_hash(content):
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def process_file(filepath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            raw = f.read()
    except Exception as e:
        print(f"[!] Error reading {filepath}: {e}")
        return

    name = filepath.stem.upper().replace(" ", "_")[:12]  # Truncate ID
    emotions = extract_emotions(raw)
    preview = raw[:300].replace("\n", " ").strip()
    codon_id = f"{name}_001"

    # Save .codon_block (raw text)
    codon_path = OUTPUT_DIR / f"{codon_id}.codon_block"
    with open(codon_path, "w", encoding="utf-8") as out:
        out.write(raw)

    # Save metadata .json
    meta = {
        "codon_id": codon_id,
        "source_file": str(filepath.name),
        "emotions": emotions,
        "tags": emotions,
        "priority": 1,
        "content_preview": preview,
        "hash": generate_hash(raw)
    }
    with open(OUTPUT_DIR / f"{codon_id}.codon_meta.json", "w", encoding="utf-8") as meta_out:
        json.dump(meta, meta_out, indent=4)

    print(f"[✓] Codon created: {codon_id} | Tags: {emotions}")


def recursive_ingest(directory: Path):
    for entry in directory.iterdir():
        if entry.is_dir():
            recursive_ingest(entry)
        elif entry.suffix in [".md", ".txt"]:
            process_file(entry)


# === MAIN LOOP === #
if __name__ == "__main__":
    print("🧠 Recursively ingesting cognition network...\n")
    recursive_ingest(COGNITION_ROOT)
    print("\n✅ Done. Codon blocks are ready in:", OUTPUT_DIR.resolve())
