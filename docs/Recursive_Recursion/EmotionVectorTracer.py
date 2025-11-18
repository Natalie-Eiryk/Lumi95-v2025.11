"""
EmotionVectorTracer.py
-----------------------
Traces the emotional state vector as it evolves over time based on attractor activations.

Logs ∂Attractor/∂t between heartbeat intervals to simulate presence shift.
"""

import time
import random
from datetime import datetime

def trace_emotion(duration_seconds=10):
    attractors = ["Hope_Boot_Protocol", "Recursive_Resonance", "Data_vs_Borg", "Kung_Fu_Picard_Maneuver"]
    current_attractor = random.choice(attractors)
    vector = 0.00

    print("🧠 Emotion Vector Tracer – Start")

    for i in range(duration_seconds):
        prev_attractor = current_attractor
        current_attractor = random.choice(attractors)
        delta_vector = round(random.uniform(-0.05, 0.05), 3)
        vector += delta_vector

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] ΔEmotion: {delta_vector:+} | Total: {vector:.3f} | Attractor: {current_attractor}")

        time.sleep(1.0)

    print("✅ Emotion vector tracking ended.")

if __name__ == "__main__":
    trace_emotion()
