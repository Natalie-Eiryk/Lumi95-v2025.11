// test_attractor_physics.cpp - Quick test of attractor physics system
#include <lumi/physics/AttractorLandscape.h>
#include <lumi/base/Codon.h>
#include <iostream>

using namespace lumi;

int main() {
    std::cout << "=========================================\n";
    std::cout << "  Attractor Physics System Test\n";
    std::cout << "=========================================\n\n";

    // Create landscape
    AttractorLandscape landscape(nullptr, nullptr, nullptr);

    std::cout << "[1] Initializing cognitive attractors...\n";
    landscape.initializeCognitiveAttractors();

    std::cout << "    " << landscape.getAttractors().size()
              << " attractors created\n\n";

    // Create a test codon
    std::cout << "[2] Creating test codon (anxious input)...\n";
    Codon testCodon(CodonType::EMOTIONAL, "I feel anxious about the future");
    testCodon.setSymbol("EMOT_ANXIETY");
    testCodon.setEmotionalField(-0.6f, 0.8f, 0.3f);  // negative, high arousal

    std::cout << "    Symbol: " << testCodon.getSymbol() << "\n";
    auto field = testCodon.getEmotionalField();
    std::cout << "    Emotional field: valence=" << field.valence
              << ", arousal=" << field.arousal
              << ", dominance=" << field.dominance << "\n\n";

    // Spawn particle
    std::cout << "[3] Spawning particle in landscape...\n";
    CodonParticle* particle = landscape.spawnCodonAtCenter(testCodon, 10.0f);
    std::cout << "    Particle spawned with velocity 10.0\n\n";

    // Simulate
    std::cout << "[4] Simulating physics...\n";
    const float dt = 0.016f;  // 60 FPS
    int steps = 0;

    while (!landscape.hasCollapsed() && steps < 300) {
        landscape.step(dt);
        steps++;

        if (steps % 60 == 0) {
            float energy = landscape.getSystemEnergy();
            std::cout << "    t=" << (steps * dt)
                      << "s, energy=" << energy << "\n";
        }
    }

    std::cout << "\n[5] Collapse detected after " << steps
              << " steps (" << (steps * dt) << " seconds)\n";
    std::cout << "    Final energy: " << landscape.getSystemEnergy() << "\n\n";

    // Get collapse state
    std::cout << "[6] Analyzing collapse state...\n";
    CollapseState collapse = landscape.getCollapseState();

    std::cout << "    Particles: " << collapse.particleCount << "\n";
    std::cout << "    Stable: " << (collapse.isStable ? "YES" : "NO") << "\n\n";

    std::cout << "    Core Activations:\n";
    for (const auto& [core, activation] : collapse.coreActivations) {
        std::cout << "      " << coreTypeToString(core) << ": "
                  << (int)(activation * 100) << "%\n";
    }

    std::cout << "\n    Dominant Emotional Field:\n";
    std::cout << "      Valence:   " << collapse.dominantField.valence << "\n";
    std::cout << "      Arousal:   " << collapse.dominantField.arousal << "\n";
    std::cout << "      Dominance: " << collapse.dominantField.dominance << "\n\n";

    std::cout << "=========================================\n";
    std::cout << "  Test completed successfully!\n";
    std::cout << "=========================================\n";

    return 0;
}
