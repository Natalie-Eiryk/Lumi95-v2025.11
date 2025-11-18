# codon_encoder.py
# Converts symbolic codon_blocks into structured binary codon register formats

import os
import json
import struct
from pathlib import Path

# === CONFIGURATION === #
INPUT_DIR = Path("./memory/codon_blocks")
OUTPUT_DIR = Path("./memory/codon_registers")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Emotion tag to 6-bit ID mapping (expandable)
EMOTION_IDS = {
    "hope": 0b000001,
    "despair": 0b000010,
    "connection": 0b000011,
    "isolation": 0b000100,
    "growth": 0b000101,
    "fear": 0b000110,
    "stillness": 0b000111,
    "anger": 0b001000,
    "love": 0b001001,
    "apathy": 0b001010,
    # Expandable up to 6-bit (0–63)
}

# Opcode examples (8-bit symbolic actions)
OPCODES = {
    "breathe": 0x01,
    "collapse": 0x02,
    "expand": 0x03,
    "sustain": 0x04,
    "reflect": 0x05,
    "connect": 0x06,
    # Expandable
}


def encode_to_reg64(meta):
    emotion = meta['emotions'][0] if meta['emotions'] else 'apathy'
    emotion_id = EMOTION_IDS.get(emotion, 0)

    opcode = 0x00
    for tag in meta['tags']:
        if tag in OPCODES:
            opcode = OPCODES[tag]
            break

    header = 0b0001  # default memory codon type
    attractor_id = int.from_bytes(meta['codon_id'].encode()[:2], 'big', signed=False)
    decay = 0x1F  # default temporal decay rate
    payload_hash = int(meta['hash'][:8], 16)  # 32-bit partial hash

    # Pack into 64-bit binary register
    reg64 = (header << 60) | (emotion_id << 54) | (opcode << 46) | (attractor_id << 30) | (decay << 22) | (payload_hash & 0x3FFFFF)
    return reg64


def process_meta_file(meta_path):
    with open(meta_path, 'r', encoding='utf-8') as f:
        meta = json.load(f)

    reg64 = encode_to_reg64(meta)
    bin_path = OUTPUT_DIR / f"{meta['codon_id']}.codon_reg64"
    with open(bin_path, 'wb') as out:
        out.write(struct.pack('>Q', reg64))  # big-endian 64-bit
    print(f"[✓] Encoded: {meta['codon_id']} → 64-bit register")


def main():
    print("🔢 Encoding codon blocks into register memory...\n")
    for file in INPUT_DIR.glob("*.codon_meta.json"):
        process_meta_file(file)
    print("\n✅ Done. Output in:", OUTPUT_DIR.resolve())


if __name__ == "__main__":
    main()
