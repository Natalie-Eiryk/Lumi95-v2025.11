# codon_reg_decoder.py
# Parses binary 64-bit codon registers into readable symbolic memory fields

import struct
import sys
from pathlib import Path

# === CONFIGURATION === #
REGISTER_DIR = Path("./memory/codon_registers")

# ID maps (same as encoder — must match)
EMOTION_IDS = {
    0b000001: "hope",
    0b000010: "despair",
    0b000011: "connection",
    0b000100: "isolation",
    0b000101: "growth",
    0b000110: "fear",
    0b000111: "stillness",
    0b001000: "anger",
    0b001001: "love",
    0b001010: "apathy"
}

OPCODES = {
    0x01: "breathe",
    0x02: "collapse",
    0x03: "expand",
    0x04: "sustain",
    0x05: "reflect",
    0x06: "connect"
}


def decode_reg64(file_path):
    with open(file_path, 'rb') as f:
        raw = f.read()
        if len(raw) != 8:
            print("[!] Invalid file size. Expected 8 bytes.")
            return
        reg = struct.unpack('>Q', raw)[0]  # big-endian 64-bit unsigned

    header      = (reg >> 60) & 0b1111
    emotion_id  = (reg >> 54) & 0b111111
    opcode_id   = (reg >> 46) & 0xFF
    attractor   = (reg >> 30) & 0xFFFF
    decay       = (reg >> 22) & 0xFF
    payload     = reg & 0x3FFFFF  # 22 bits

    print("============================")
    print(f"File: {file_path.name}")
    print("----------------------------")
    print(f"Header     : {bin(header)} → Type: {'MEMORY' if header == 0b0001 else 'UNKNOWN'}")
    print(f"Emotion ID : {bin(emotion_id)} → {EMOTION_IDS.get(emotion_id, 'unknown')}")
    print(f"Opcode     : {hex(opcode_id)} → {OPCODES.get(opcode_id, 'none')}")
    print(f"Attractor  : 0x{attractor:04X}")
    print(f"Decay Rate : {decay}")
    print(f"Payload    : 0x{payload:06X} (partial SHA-256 hash)")
    print("============================\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python codon_reg_decoder.py <filename> or --all")
        return

    arg = sys.argv[1]
    if arg == "--all":
        for file in REGISTER_DIR.glob("*.codon_reg64"):
            decode_reg64(file)
    else:
        decode_reg64(Path(arg))


if __name__ == "__main__":
    main()