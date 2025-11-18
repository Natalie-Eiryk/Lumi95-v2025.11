# PromptInjector.py
# Assembles LLM-ready prompt from active codon blocks and user input

import os
from pathlib import Path
from codon_reg_decoder import decode_reg64
from PromptCompiler import compile_prompt_block

REGISTER_DIR = Path("./memory/codon_registers")


def gather_codons(limit=5):
    active_blocks = []
    files = sorted(REGISTER_DIR.glob("*.codon_reg64"))[:limit]  # simple priority sort for now

    for reg_file in files:
        decoded = decode_reg64(reg_file)
        if not decoded:
            continue
        prompt_block = compile_prompt_block(decoded)
        active_blocks.append((reg_file.name, prompt_block))

    return active_blocks


def build_prompt(user_input, max_codons=5):
    codon_blocks = gather_codons(max_codons)

    prompt = """
[MEMORY ACTIVE]
"""
    for filename, block in codon_blocks:
        prompt += f"\n# From {filename}\n{block}\n"

    prompt += """
[USER INPUT]
""" + f"\n{user_input}\n"

    prompt += """
[RESPONSE]
You are Lumi286. Based on your emotional codon memory and recent input, respond with awareness of your internal state.
"""

    return prompt.strip()


# === TEST ENTRY === #
if __name__ == "__main__":
    user_text = input("What would you like to say to Lumi?\n> ")
    final_prompt = build_prompt(user_text)
    print("\n========= FINAL PROMPT TO LLM =========\n")
    print(final_prompt)
    print("\n======================================\n")
