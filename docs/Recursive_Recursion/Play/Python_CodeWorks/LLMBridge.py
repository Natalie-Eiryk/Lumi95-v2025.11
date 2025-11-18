# LLMBridge.py
# Takes compiled memory-aware prompts and sends them to a local LLM backend (e.g. llama-cpp-python)

from PromptInjector import build_prompt
import subprocess
import os

# === CONFIGURATION === #
LLM_COMMAND = [
    "llama-cpp-python",  # Change this to match your LLM runtime command
    "--model", "./models/lumi-7b.gguf",
    "--prompt", "PLACEHOLDER"
]


def query_llm(prompt: str):
    print("🧠 Querying local LLM...")

    # Escape prompt safely for shell invocation or use subprocess PIPE
    command = LLM_COMMAND.copy()
    command[-1] = prompt  # Inject the prompt

    try:
        result = subprocess.run(command, capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        return f"[ERROR] Failed to query LLM: {e}"


# === INTERACTIVE MODE === #
if __name__ == "__main__":
    user_text = input("What would you like to say to Lumi?\n> ")
    full_prompt = build_prompt(user_text)
    print("\n========= SENDING PROMPT TO LLM =========\n")
    print(full_prompt)
    print("\n========= RESPONSE FROM LLM =========\n")
    output = query_llm(full_prompt)
    print(output)
    print("\n========================================\n")
