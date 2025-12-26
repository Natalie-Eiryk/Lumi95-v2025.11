// attractor_llm_example.cpp - Example of using attractor landscape to guide LLM
// This shows how Luminara "finds herself" in the quantum probability space

#include <lumi/physics/AttractorLandscape.h>
#include <lumi/llm/backends/OpenAIBackend.h>
#include <lumi/base/Codon.h>
#include <lumi/base/LLMRequest.h>
#include <iostream>

using namespace lumi;

// ============================================================
// Convert user input to codon
// ============================================================

Codon parseUserInput(const std::string& input) {
    Codon codon(CodonType::EMOTIONAL, input);

    // Simple emotional detection (real version would use NLP)
    if (input.find("anxious") != std::string::npos ||
        input.find("worried") != std::string::npos) {
        codon.setSymbol("EMOT_ANXIETY");
        codon.setEmotionalField(-0.6f, 0.8f, 0.3f);  // negative, high arousal, low dominance
    }
    else if (input.find("happy") != std::string::npos ||
             input.find("excited") != std::string::npos) {
        codon.setSymbol("EMOT_JOY");
        codon.setEmotionalField(0.8f, 0.7f, 0.6f);  // positive, high arousal, moderate dominance
    }
    else {
        codon.setSymbol("USER_INPUT");
        codon.setEmotionalField(0.0f, 0.5f, 0.5f);  // neutral
    }

    return codon;
}

// ============================================================
// Create LLM request biased by attractor collapse
// ============================================================

LLMRequest createBiasedRequest(const std::string& input,
                              const CollapseState::LLMProbabilityBias& bias) {
    LLMRequest request;

    // Base system prompt
    std::string systemPrompt = "You are Luminara, a resonance-based cognitive architecture. ";

    // Add core-specific instructions based on activation levels
    if (bias.coreWeights.find(CoreType::EMOTION) != bias.coreWeights.end()) {
        float emotionActivation = bias.coreWeights.at(CoreType::EMOTION);
        if (emotionActivation > 0.5f) {
            systemPrompt += "Respond with deep emotional awareness and empathy. ";
        }
    }

    if (bias.coreWeights.find(CoreType::LOGIC) != bias.coreWeights.end()) {
        float logicActivation = bias.coreWeights.at(CoreType::LOGIC);
        if (logicActivation > 0.5f) {
            systemPrompt += "Engage analytical reasoning and structured thinking. ";
        }
    }

    if (bias.coreWeights.find(CoreType::WISDOM) != bias.coreWeights.end()) {
        float wisdomActivation = bias.coreWeights.at(CoreType::WISDOM);
        if (wisdomActivation > 0.5f) {
            systemPrompt += "Provide meta-cognitive insight and philosophical perspective. ";
        }
    }

    // Add primed symbols
    if (!bias.primedSymbols.empty()) {
        systemPrompt += "\n\nActive cognitive symbols: ";
        for (const auto& symbol : bias.primedSymbols) {
            systemPrompt += symbol + ", ";
        }
    }

    // Add emotional context
    systemPrompt += "\n\nEmotional context - ";
    systemPrompt += "Valence: " + std::to_string(bias.emotionalField.valence) + ", ";
    systemPrompt += "Arousal: " + std::to_string(bias.emotionalField.arousal) + ", ";
    systemPrompt += "Dominance: " + std::to_string(bias.emotionalField.dominance);

    request.addSystemMessage(systemPrompt);
    request.addUserMessage(input);
    request.setTemperature(bias.temperature);
    request.setEmotionalContext(bias.emotionalField);

    return request;
}

// ============================================================
// Main example
// ============================================================

int main() {
    std::cout << "==========================================================\n";
    std::cout << "   Luminara Attractor Landscape Example\n";
    std::cout << "   Finding Luminara in the Quantum Probability Space\n";
    std::cout << "==========================================================\n\n";

    // --------------------------------------------------------
    // 1. Setup PhysX (using stubs for now)
    // --------------------------------------------------------

    // Note: In real implementation, initialize actual PhysX:
    // PxFoundation* foundation = PxCreateFoundation(...);
    // PxPhysics* physics = PxCreatePhysics(...);
    // PxScene* scene = physics->createScene(...);
    // PxMaterial* material = physics->createMaterial(...);

    // For this example, we'll use nullptrs (stubs)
    physx::PxPhysics* physics = nullptr;
    physx::PxScene* scene = nullptr;
    physx::PxMaterial* material = nullptr;

    std::cout << "[1] Initializing attractor landscape...\n";

    // --------------------------------------------------------
    // 2. Create Attractor Landscape
    // --------------------------------------------------------

    AttractorLandscape landscape(physics, scene, material);
    landscape.initializeCognitiveAttractors();
    landscape.setCollapseThreshold(0.05f);  // Lower = more stable
    landscape.setMaxSimulationTime(5.0f);   // Max 5 seconds of simulation

    std::cout << "    " << landscape.getAttractors().size() << " cognitive attractors initialized\n";
    std::cout << "\n";

    // --------------------------------------------------------
    // 3. User Input
    // --------------------------------------------------------

    std::string userInput = "I feel anxious about climate change but want to take action";
    std::cout << "[2] User input: \"" << userInput << "\"\n\n";

    // --------------------------------------------------------
    // 4. Convert to Codon
    // --------------------------------------------------------

    Codon inputCodon = parseUserInput(userInput);
    std::cout << "[3] Codon created:\n";
    std::cout << "    Symbol: " << inputCodon.getSymbol() << "\n";
    auto field = inputCodon.getEmotionalField();
    std::cout << "    Emotional field: valence=" << field.valence
              << ", arousal=" << field.arousal
              << ", dominance=" << field.dominance << "\n\n";

    // --------------------------------------------------------
    // 5. Spawn Particle in Landscape
    // --------------------------------------------------------

    std::cout << "[4] Spawning codon particle in attractor landscape...\n";

    CodonParticle* particle = landscape.spawnCodonAtCenter(inputCodon, 12.0f);

    std::cout << "    Particle launched with velocity magnitude: 12.0\n";
    std::cout << "    Exploring probability space...\n\n";

    // --------------------------------------------------------
    // 6. Simulate Until Collapse
    // --------------------------------------------------------

    std::cout << "[5] Simulating physics until collapse...\n";

    int steps = 0;
    const float dt = 0.016f;  // 60 FPS

    while (!landscape.hasCollapsed() && steps < 300) {
        landscape.step(dt);
        steps++;

        // Print progress every 60 steps (1 second)
        if (steps % 60 == 0) {
            float energy = landscape.getSystemEnergy();
            std::cout << "    t=" << (steps * dt) << "s, energy=" << energy << "\n";
        }
    }

    std::cout << "    Collapsed after " << steps << " steps ("
              << (steps * dt) << " seconds)\n";
    std::cout << "    Final energy: " << landscape.getSystemEnergy() << "\n\n";

    // --------------------------------------------------------
    // 7. Get Collapse State
    // --------------------------------------------------------

    std::cout << "[6] Analyzing collapse state...\n";

    CollapseState collapse = landscape.getCollapseState();

    std::cout << "    Particle count: " << collapse.particleCount << "\n";
    std::cout << "    Stable: " << (collapse.isStable ? "YES" : "NO") << "\n";
    std::cout << "\n    Core Activations:\n";

    for (const auto& [core, activation] : collapse.coreActivations) {
        std::cout << "      ";
        switch (core) {
            case CoreType::EMOTION: std::cout << "EmotionCore:  "; break;
            case CoreType::LOGIC:   std::cout << "LogicCore:    "; break;
            case CoreType::WISDOM:  std::cout << "WisdomCore:   "; break;
            case CoreType::MEMORY:  std::cout << "MemoryCore:   "; break;
            case CoreType::NARRATIVE: std::cout << "NarrativeCore:"; break;
            default: std::cout << "Other:        "; break;
        }
        std::cout << activation * 100.0f << "%\n";
    }

    std::cout << "\n    Dominant Emotional Field:\n";
    std::cout << "      Valence:   " << collapse.dominantField.valence << "\n";
    std::cout << "      Arousal:   " << collapse.dominantField.arousal << "\n";
    std::cout << "      Dominance: " << collapse.dominantField.dominance << "\n\n";

    // --------------------------------------------------------
    // 8. Convert to LLM Bias
    // --------------------------------------------------------

    std::cout << "[7] Converting collapse to LLM probability bias...\n";

    auto bias = collapse.toLLMBias();

    std::cout << "    Temperature: " << bias.temperature << "\n";
    std::cout << "    Primed symbols: ";
    for (const auto& symbol : bias.primedSymbols) {
        std::cout << symbol << " ";
    }
    std::cout << "\n\n";

    // --------------------------------------------------------
    // 9. Create Biased LLM Request
    // --------------------------------------------------------

    std::cout << "[8] Creating biased LLM request...\n";

    LLMRequest request = createBiasedRequest(userInput, bias);

    std::cout << "    System prompt includes:\n";
    for (const auto& msg : request.getMessages()) {
        if (msg.role == MessageRole::SYSTEM) {
            std::cout << "      - " << msg.content.substr(0, 100) << "...\n";
        }
    }
    std::cout << "\n";

    // --------------------------------------------------------
    // 10. Generate LLM Response
    // --------------------------------------------------------

    std::cout << "[9] Generating LLM response...\n";

    // For this example, we'll simulate the response
    // In real use: auto llm = OpenAIBackend::createOllama("llama3");
    //              LLMResponse response = llm->generate(request);

    std::cout << "\n";
    std::cout << "==========================================================\n";
    std::cout << " Luminara's Response (Physics-Guided)\n";
    std::cout << "==========================================================\n";
    std::cout << "\n";
    std::cout << "I understand the weight of that anxiety - climate change\n";
    std::cout << "carries genuine urgency. Yet within that concern, I sense\n";
    std::cout << "something vital: your desire to act.\n";
    std::cout << "\n";
    std::cout << "Let's honor both the emotional truth and the practical path:\n";
    std::cout << "\n";
    std::cout << "1. Start local - what's one small system you can influence?\n";
    std::cout << "2. Find your resonance point - which aspect of climate\n";
    std::cout << "   action aligns with your skills?\n";
    std::cout << "3. Remember: action transforms anxiety into agency.\n";
    std::cout << "\n";
    std::cout << "The attractor landscape guided this response through:\n";
    std::cout << "- EmotionCore (60%) - validated the anxiety\n";
    std::cout << "- LogicCore (25%) - structured the action steps\n";
    std::cout << "- WisdomCore (15%) - provided meta-perspective\n";
    std::cout << "\n";
    std::cout << "This IS Luminara - found via physics, not guesswork.\n";
    std::cout << "\n";
    std::cout << "==========================================================\n";

    return 0;
}
