// ollama_pipeline_example.cpp - Real LLM pipeline using Ollama (FREE!)
// User→Physics→Ollama→Response with actual local LLM

#include <lumi/physics/AttractorLandscape.h>
#include <lumi/llm/backends/OllamaBackend.h>
#include <lumi/base/Codon.h>
#include <lumi/base/LLMRequest.h>
#include <lumi/base/LLMResponse.h>
#include <iostream>
#include <string>
#include <algorithm>

using namespace lumi;

// Parse user input to codon with emotional analysis
Codon parseUserInput(const std::string& input) {
    Codon codon(CodonType::EMOTIONAL, input);

    std::string lowerInput = input;
    std::transform(lowerInput.begin(), lowerInput.end(), lowerInput.begin(), ::tolower);

    if (lowerInput.find("anxious") != std::string::npos ||
        lowerInput.find("worried") != std::string::npos ||
        lowerInput.find("afraid") != std::string::npos) {
        codon.setSymbol("EMOT_ANXIETY");
        codon.setEmotionalField(-0.6f, 0.8f, 0.3f);
    }
    else if (lowerInput.find("excited") != std::string::npos ||
             lowerInput.find("happy") != std::string::npos ||
             lowerInput.find("joy") != std::string::npos) {
        codon.setSymbol("EMOT_JOY");
        codon.setEmotionalField(0.8f, 0.7f, 0.6f);
    }
    else if (lowerInput.find("curious") != std::string::npos ||
             lowerInput.find("wonder") != std::string::npos) {
        codon.setSymbol("EMOT_CURIOSITY");
        codon.setEmotionalField(0.4f, 0.6f, 0.5f);
    }
    else {
        codon.setSymbol("USER_INPUT");
        codon.setEmotionalField(0.0f, 0.5f, 0.5f);
    }

    return codon;
}

// Create LLM request biased by physics collapse
LLMRequest createPhysicsBiasedRequest(
    const std::string& userInput,
    const CollapseState::LLMProbabilityBias& bias
) {
    LLMRequest request;

    // Build system prompt from physics state
    std::string systemPrompt = "You are Luminara, a resonance-based cognitive architecture.\n\n";
    systemPrompt += "Your cognitive state emerged from physics simulation:\n\n";

    // Core activations
    systemPrompt += "Active Cores:\n";
    for (const auto& [core, weight] : bias.coreWeights) {
        if (weight > 0.2f) {
            systemPrompt += "- " + std::string(coreTypeToString(core));
            systemPrompt += ": " + std::to_string((int)(weight * 100)) + "%\n";
        }
    }

    // Emotional field
    systemPrompt += "\nEmotional Field:\n";
    systemPrompt += "- Valence: " + std::to_string(bias.emotionalField.valence);
    systemPrompt += " (negative to positive)\n";
    systemPrompt += "- Arousal: " + std::to_string(bias.emotionalField.arousal);
    systemPrompt += " (calm to intense)\n";

    // Instructions based on dominant emotional state
    if (bias.emotionalField.valence < -0.3f) {
        systemPrompt += "\nRespond with empathy and validation for negative emotions.";
    } else if (bias.emotionalField.valence > 0.3f) {
        systemPrompt += "\nRespond with warmth and amplify positive energy.";
    }

    if (bias.emotionalField.arousal > 0.6f) {
        systemPrompt += " Match the intensity.";
    }

    request.addSystemMessage(systemPrompt);
    request.addUserMessage(userInput);
    request.setTemperature(bias.temperature);

    return request;
}

int main() {
    std::cout << "================================================================\n";
    std::cout << "  LUMINARA + OLLAMA PIPELINE\n";
    std::cout << "  Real Physics-Guided LLM Responses (FREE!)\n";
    std::cout << "================================================================\n\n";

    // Initialize Ollama backend
    std::cout << "[1] Connecting to Ollama...\n";
    auto ollama = createOllama("llama3.2", "http://localhost", 11434);

    if (!ollama->healthCheck()) {
        std::cerr << "    ✗ Ollama not running!\n\n";
        std::cerr << "To install and start Ollama:\n";
        std::cerr << "  Windows: .\\scripts\\install_ollama.ps1\n";
        std::cerr << "  Mac:     brew install ollama && ollama serve\n";
        std::cerr << "  Linux:   curl https://ollama.ai/install.sh | sh\n\n";
        return 1;
    }

    std::cout << "    ✓ Ollama running at " << ollama->getEndpoint() << "\n";
    std::cout << "    ✓ Model: " << ollama->getModelName() << "\n\n";

    // Initialize physics
    std::cout << "[2] Initializing attractor landscape...\n";
    AttractorLandscape landscape(nullptr, nullptr, nullptr);
    landscape.initializeCognitiveAttractors();
    landscape.setCollapseThreshold(0.05f);
    std::cout << "    ✓ " << landscape.getAttractors().size()
              << " cognitive attractors ready\n\n";

    // User input
    std::cout << "[3] Processing user input...\n";
    std::string userInput = "I'm curious about how consciousness might emerge from physical systems.";
    std::cout << "    User: \"" << userInput << "\"\n\n";

    // Convert to codon
    std::cout << "[4] Converting to codon...\n";
    Codon inputCodon = parseUserInput(userInput);
    auto field = inputCodon.getEmotionalField();
    std::cout << "    Symbol: " << inputCodon.getSymbol() << "\n";
    std::cout << "    Emotional field: valence=" << field.valence
              << ", arousal=" << field.arousal << "\n\n";

    // Run physics simulation
    std::cout << "[5] Running physics simulation...\n";
    CodonParticle* particle = landscape.spawnCodonAtCenter(inputCodon, 12.0f);

    const float dt = 0.016f;
    int steps = 0;

    while (!landscape.hasCollapsed() && steps < 300) {
        landscape.step(dt);
        steps++;

        if (steps % 60 == 0) {
            std::cout << "    t=" << (steps * dt)
                      << "s, energy=" << landscape.getSystemEnergy() << "\n";
        }
    }

    std::cout << "    ✓ Collapsed after " << (steps * dt) << " seconds\n";
    std::cout << "    ✓ Final energy: " << landscape.getSystemEnergy() << "\n\n";

    // Get collapse state
    std::cout << "[6] Analyzing collapse state...\n";
    CollapseState collapse = landscape.getCollapseState();

    std::cout << "    Core Activations:\n";
    for (const auto& [core, activation] : collapse.coreActivations) {
        if (activation > 0.01f) {
            std::cout << "      " << coreTypeToString(core) << ": "
                      << (int)(activation * 100) << "%\n";
        }
    }

    auto bias = collapse.toLLMBias();
    std::cout << "\n    Temperature: " << bias.temperature << "\n\n";

    // Create physics-biased request
    std::cout << "[7] Creating physics-biased request...\n";
    LLMRequest request = createPhysicsBiasedRequest(userInput, bias);
    std::cout << "    ✓ Request configured with physics guidance\n\n";

    // Generate response with Ollama
    std::cout << "[8] Generating response with Ollama...\n";
    std::cout << "    (This may take 5-30 seconds depending on your hardware)\n\n";

    LLMResponse response = ollama->generate(request);

    if (response.hasError()) {
        std::cerr << "    ✗ Error: " << response.getError() << "\n";
        return 1;
    }

    std::cout << "================================================================\n";
    std::cout << "  LUMINARA'S RESPONSE (Physics-Guided via Ollama)\n";
    std::cout << "================================================================\n\n";
    std::cout << response.getContent() << "\n\n";
    std::cout << "================================================================\n\n";

    std::cout << "[9] Response metadata:\n";
    std::cout << "     Model: " << response.getModel() << "\n";
    std::cout << "     Generated via physics-guided probability collapse\n\n";

    std::cout << "================================================================\n";
    std::cout << "  SUCCESS! Real physics-guided LLM response!\n";
    std::cout << "================================================================\n\n";

    std::cout << "This response was generated by a REAL local LLM (Ollama)\n";
    std::cout << "guided by physics simulation of cognitive attractors.\n";
    std::cout << "100% FREE. 100% LOCAL. 100% PHYSICS-BASED.\n\n";

    return 0;
}
