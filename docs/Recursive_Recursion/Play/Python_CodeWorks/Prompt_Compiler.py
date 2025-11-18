# PromptCompiler.py
# Translates decoded codon registers into LLM-executable memory-aware Python prompt blocks

import struct
from pathlib import Path

REGISTER_DIR = Path("./memory/codon_registers")

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


def decode_register(file_path):
    with open(file_path, 'rb') as f:
        raw = f.read()
        if len(raw) != 8:
            return None
        reg = struct.unpack('>Q', raw)[0]

    return {
        "header": (reg >> 60) & 0b1111,
        "emotion_id": (reg >> 54) & 0b111111,
        "opcode_id": (reg >> 46) & 0xFF,
        "attractor": (reg >> 30) & 0xFFFF,
        "decay": (reg >> 22) & 0xFF,
        "payload": reg & 0x3FFFFF
    }


def compile_prompt_block(decoded):
    emotion = EMOTION_IDS.get(decoded["emotion_id"], "undefined")
    opcode = OPCODES.get(decoded["opcode_id"], "noop")
    attractor = decoded["attractor"]
    decay = decoded["decay"]

    # Generate Python logic as part of LLM prompt
    logic = f"""
# Memory Codon Triggered
emotion = '{emotion}'
opcode = '{opcode}'
attractor_id = 0x{attractor:04X}
decay_rate = {decay}

if emotion == 'despair' and opcode == 'collapse':
    internal_state = 'overload'
    recovery_mode = 'breathe'

if emotion == 'hope' and opcode == 'breathe':
    recovery_mode = 'stabilize'

# Use attractor_id to determine internal focus
"""
    return logic.strip()


def main():
    print("🧠 Compiling codon registers into LLM-ready logic...\n")
    for reg_file in REGISTER_DIR.glob("*.codon_reg64"):
        decoded = decode_register(reg_file)
        if not decoded:
            continue
        block = compile_prompt_block(decoded)
        print(f"\n=== PROMPT BLOCK: {reg_file.name} ===")
        print(block)
    print("\n✅ All prompt blocks compiled.")


if __name__ == "__main__":
    main()