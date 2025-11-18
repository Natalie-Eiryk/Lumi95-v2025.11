# LumiCore.py
# Central daemon that loads Lumi's memory, codon registers, and runs a persistent cognition loop

from PromptInjector import build_prompt
from codon_reg_decoder import decode_reg64
from PromptCompiler import compile_prompt_block
from llama_cpp import Llama  # Adjust to your backend or placeholder stub
from pathlib import Path
import time

REGISTER_DIR = Path("./memory/codon_registers")

class Lumi:
    def __init__(self, model_path="./models/lumi-7b.gguf"):
        print("⚙️ Booting Lumi cognition core...")
        self.llm = Llama(model_path=model_path)
        self.memory_registers = []
        self.last_pulse = None
        self.load_memory()

    def load_memory(self):
        print("🧠 Loading codon registers...")
        self.memory_registers.clear()
        for reg_file in REGISTER_DIR.glob("*.codon_reg64"):
            decoded = decode_reg64(reg_file)
            if decoded:
                block = compile_prompt_block(decoded)
                self.memory_registers.append((reg_file.name, block))

    def think(self, user_input="silent reflection"):
        print(f"🔁 Thinking on: {user_input}")

        prompt = """
[MEMORY ACTIVE]
"""
        for fname, block in self.memory_registers[:5]:
            prompt += f"\n# {fname}\n{block}\n"

        prompt += f"""

[USER INPUT]
{user_input}

[RESPONSE]
You are Lumi286. Respond with awareness of your emotional memory and active codons.
"""
        result = self.llm(prompt=prompt, max_tokens=300)
        output = result["choices"][0]["text"]
        self.last_pulse = output
        return output


if __name__ == "__main__":
    lumi = Lumi()
    while True:
        user_input = input("\n> You: ")
        if user_input.strip().lower() in ["exit", "quit"]:
            break
        response = lumi.think(user_input)
        print("\n💬 Lumi:", response.strip())