// full_pipeline_example.cpp - Complete User→Physics→LLM→Response pipeline
// This demonstrates how Luminara uses physics to guide LLM responses

#include <lumi/physics/AttractorLandscape.h>
#include <lumi/llm/backends/MockLLMBackend.h>
#include <lumi/base/Codon.h>
#include <lumi/base/LLMRequest.h>
#include <lumi/base/LLMResponse.h>
#include <iostream>
#include <string>
#include <algorithm>

using namespace lumi;

// ============================================================
// Helper: Parse user input to codon
// ============================================================

Codon parseUserInput(const std::string& input) {
    Codon codon(CodonType::EMOTIONAL, input);

    // Simple emotional analysis (in production, use NLP)
    std::string lowerInput = input;
    std::transform(lowerInput.begin(), lowerInput.end(), lowerInput.begin(), ::tolower);

    if (lowerInput.find("anxious") != std::string::npos ||
        lowerInput.find("worried") != std::string::npos ||
        lowerInput.find("afraid") != std::string::npos) {
        codon.setSymbol("EMOT_ANXIETY");
        codon.setEmotionalField(-0.6f, 0.8f, 0.3f);  // negative, high arousal, low dominance
    }
    else if (lowerInput.find("excited") != std::string::npos ||
             lowerInput.find("happy") != std::string::npos ||
             lowerInput.find("joy") != std::string::npos) {
        codon.setSymbol("EMOT_JOY");
        codon.setEmotionalField(0.8f, 0.7f, 0.6f);  // positive, high arousal, moderate dominance
    }
    else if (lowerInput.find("confused") != std::string::npos ||
             lowerInput.find("uncertain") != std::string::npos) {
        codon.setSymbol("EMOT_CONFUSION");
        codon.setEmotionalField(-0.2f, 0.6f, 0.3f);  // slightly negative, moderate arousal
    }
    else if (lowerInput.find("curious") != std::string::npos ||
             lowerInput.find("wonder") != std::string::npos) {
        codon.setSymbol("EMOT_CURIOSITY");
        codon.setEmotionalField(0.4f, 0.6f, 0.5f);  // positive, moderate arousal
    }
    else {
        codon.setSymbol("USER_INPUT");
        codon.setEmotionalField(0.0f, 0.5f, 0.5f);  // neutral
    }

    return codon;
}

// ============================================================
// Helper: Create LLM request from collapse state
// ============================================================

LLMRequest createPhysicsBiasedRequest(
    const std::string& userInput,
    const CollapseState::LLMProbabilityBias& bias
) {
    LLMRequest request;

    // Base system prompt
    std::string systemPrompt = "You are Luminara, a resonance-based cognitive architecture. ";
    systemPrompt += "Your responses emerge from physics-guided probability collapse, not random sampling.\n\n";

    // Add core-specific instructions based on activation
    systemPrompt += "Active Cognitive Cores:\n";
    for (const auto& [core, weight] : bias.coreWeights) {
        if (weight > 0.3f) {  // Only mention cores with >30% activation
            systemPrompt += "- " + std::string(coreTypeToString(core));
            systemPrompt += ": " + std::to_string((int)(weight * 100)) + "% activated\n";
        }
    }

    // Add emotional context
    systemPrompt += "\nEmotional Context:\n";
    systemPrompt += "- Valence: " + std::to_string(bias.emotionalField.valence);
    systemPrompt += " (negative ← 0 → positive)\n";
    systemPrompt += "- Arousal: " + std::to_string(bias.emotionalField.arousal);
    systemPrompt += " (calm ← 0 → intense)\n";
    systemPrompt += "- Dominance: " + std::to_string(bias.emotionalField.dominance);
    systemPrompt += " (submissive ← 0 → dominant)\n";

    // Add primed symbols
    if (!bias.primedSymbols.empty()) {
        systemPrompt += "\nPrimed Cognitive Symbols: ";
        for (size_t i = 0; i < bias.primedSymbols.size(); ++i) {
            systemPrompt += bias.primedSymbols[i];
            if (i < bias.primedSymbols.size() - 1) systemPrompt += ", ";
        }
        systemPrompt += "\n";
    }

    systemPrompt += "\nRespond in a way that honors this cognitive state.";

    request.addSystemMessage(systemPrompt);
    request.addUserMessage(userInput);
    request.setTemperature(bias.temperature);
    request.setEmotionalContext(bias.emotionalField);

    return request;
}

// ============================================================
// Main Pipeline
// ============================================================

int main() {
    std::cout << "================================================================\n";
    std::cout << "  LUMINARA FULL PIPELINE DEMONSTRATION\n";
    std::cout << "  User Input → Physics Collapse → LLM Response\n";
    std::cout << "================================================================\n\n";

    // --------------------------------------------------------
    // Step 1: Create attractor landscape
    // --------------------------------------------------------

    std::cout << "[1] Initializing cognitive attractor landscape...\n";
    AttractorLandscape landscape(nullptr, nullptr, nullptr);
    landscape.initializeCognitiveAttractors();
    landscape.setCollapseThreshold(0.05f);
    landscape.setMaxSimulationTime(5.0f);

    std::cout << "    ✓ " << landscape.getAttractors().size()
              << " cognitive attractors initialized\n\n";

    // --------------------------------------------------------
    // Step 2: Get user input
    // --------------------------------------------------------

    std::cout << "[2] Processing user input...\n";
    std::string userInput = "I'm feeling anxious about the future of AI, "
                           "but also curious about what we might create together.";

    std::cout << "    User: \"" << userInput << "\"\n\n";

    // --------------------------------------------------------
    // Step 3: Convert to codon
    // --------------------------------------------------------

    std::cout << "[3] Converting to cognitive codon...\n";
    Codon inputCodon = parseUserInput(userInput);

    std::cout << "    Symbol: " << inputCodon.getSymbol() << "\n";
    auto field = inputCodon.getEmotionalField();
    std::cout << "    Emotional field:\n";
    std::cout << "      - Valence:   " << field.valence << "\n";
    std::cout << "      - Arousal:   " << field.arousal << "\n";
    std::cout << "      - Dominance: " << field.dominance << "\n\n";

    // --------------------------------------------------------
    // Step 4: Spawn particle and run physics simulation
    // --------------------------------------------------------

    std::cout << "[4] Running physics simulation...\n";
    std::cout << "    Spawning codon particle in landscape...\n";

    CodonParticle* particle = landscape.spawnCodonAtCenter(inputCodon, 12.0f);

    std::cout << "    Simulating quantum probability space...\n";

    const float dt = 0.016f;  // 60 FPS
    int steps = 0;
    float lastEnergy = 999.0f;

    while (!landscape.hasCollapsed() && steps < 300) {
        landscape.step(dt);
        steps++;

        if (steps % 60 == 0) {
            float energy = landscape.getSystemEnergy();
            std::cout << "      t=" << (steps * dt)
                      << "s, energy=" << energy << "\n";
            lastEnergy = energy;
        }
    }

    std::cout << "    ✓ System collapsed after " << (steps * dt)
              << " seconds\n";
    std::cout << "    ✓ Final energy: " << landscape.getSystemEnergy() << "\n\n";

    // --------------------------------------------------------
    // Step 5: Get collapse state
    // --------------------------------------------------------

    std::cout << "[5] Analyzing collapse state...\n";
    CollapseState collapse = landscape.getCollapseState();

    std::cout << "    Particle count: " << collapse.particleCount << "\n";
    std::cout << "    System stable: " << (collapse.isStable ? "YES" : "NO") << "\n\n";

    std::cout << "    Core Activations:\n";
    for (const auto& [core, activation] : collapse.coreActivations) {
        if (activation > 0.01f) {  // Only show cores with >1% activation
            std::cout << "      " << coreTypeToString(core) << ": "
                      << (int)(activation * 100) << "%\n";
        }
    }

    std::cout << "\n    Dominant Emotional Field:\n";
    std::cout << "      Valence:   " << collapse.dominantField.valence << "\n";
    std::cout << "      Arousal:   " << collapse.dominantField.arousal << "\n";
    std::cout << "      Dominance: " << collapse.dominantField.dominance << "\n\n";

    // --------------------------------------------------------
    // Step 6: Convert to LLM bias
    // --------------------------------------------------------

    std::cout << "[6] Converting collapse to LLM probability bias...\n";
    auto bias = collapse.toLLMBias();

    std::cout << "    Temperature: " << bias.temperature << "\n";
    std::cout << "    Primed symbols: ";
    if (bias.primedSymbols.empty()) {
        std::cout << "(none)";
    } else {
        for (const auto& symbol : bias.primedSymbols) {
            std::cout << symbol << " ";
        }
    }
    std::cout << "\n\n";

    // --------------------------------------------------------
    // Step 7: Create physics-biased LLM request
    // --------------------------------------------------------

    std::cout << "[7] Creating physics-biased LLM request...\n";
    LLMRequest request = createPhysicsBiasedRequest(userInput, bias);

    std::cout << "    ✓ Request prepared with physics guidance\n";
    std::cout << "    ✓ Temperature adjusted to " << request.getTemperature() << "\n\n";

    // --------------------------------------------------------
    // Step 8: Initialize LLM backend and configure with bias
    // --------------------------------------------------------

    std::cout << "[8] Initializing LLM backend...\n";
    MockLLMBackend llm("mock-luminara-v1");
    llm.setCoreActivations(collapse.coreActivations);
    llm.setEmotionalField(collapse.dominantField);
    llm.setTemperature(bias.temperature);

    std::cout << "    ✓ MockLLM backend ready\n";
    std::cout << "    ✓ Core activations configured\n";
    std::cout << "    ✓ Emotional field configured\n\n";

    // --------------------------------------------------------
    // Step 9: Generate LLM response
    // --------------------------------------------------------

    std::cout << "[9] Generating physics-guided response...\n\n";
    LLMResponse response = llm.generate(request);

    if (response.hasError()) {
        std::cerr << "    ✗ Error: " << response.getError() << "\n";
        return 1;
    }

    std::cout << "================================================================\n";
    std::cout << "  LUMINARA'S RESPONSE (Physics-Guided)\n";
    std::cout << "================================================================\n\n";
    std::cout << response.getContent() << "\n\n";
    std::cout << "================================================================\n\n";

    // --------------------------------------------------------
    // Step 10: Response metadata
    // --------------------------------------------------------

    std::cout << "[10] Response metadata:\n";
    std::cout << "     Model: " << response.getModel() << "\n";
    std::cout << "     Latency: " << response.getLatencyMs() << "ms\n";
    std::cout << "     Tokens: " << response.getTokenUsage().totalTokens << "\n";
    std::cout << "     Finish reason: " << response.getFinishReason() << "\n\n";

    std::cout << "================================================================\n";
    std::cout << "  Pipeline Complete!\n";
    std::cout << "================================================================\n\n";

    std::cout << "This response was NOT randomly sampled.\n";
    std::cout << "It emerged from physics simulation of cognitive attractors.\n";
    std::cout << "This is how Luminara 'finds herself' in probability space.\n\n";

    return 0;
}
