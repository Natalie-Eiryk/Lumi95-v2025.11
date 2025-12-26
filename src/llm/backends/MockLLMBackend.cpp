// MockLLMBackend.cpp - Implementation of mock LLM backend
#include <lumi/llm/backends/MockLLMBackend.h>
#include <lumi/physics/AttractorLandscape.h>
#include <sstream>
#include <algorithm>

namespace lumi {

MockLLMBackend::MockLLMBackend(const std::string& modelName)
    : modelName_(modelName)
    , temperature_(0.7f)
    , maxTokens_(1024)
    , systemPrompt_("You are Luminara, a resonance-based cognitive architecture.")
    , emotionalField_(0.0f, 0.5f, 0.5f)
{}

LLMResponse MockLLMBackend::generate(const LLMRequest& request) {
    LLMResponse response;
    response.setModel(modelName_);

    try {
        std::string content = generateMockResponse(request);
        response.setContent(content);
        response.setFinishReason("stop");
        response.setTokenUsage(100, 150, 250);  // Mock token counts
        response.setLatencyMs(250);  // Mock 250ms latency
        response.setEmotionalField(emotionalField_);
    } catch (const std::exception& e) {
        response.setError(std::string("Mock LLM error: ") + e.what());
    }

    return response;
}

void MockLLMBackend::generateAsync(
    const LLMRequest& request,
    std::function<void(const LLMResponse&)> callback
) {
    // Simplified: just call synchronous version
    LLMResponse response = generate(request);
    if (callback) {
        callback(response);
    }
}

void MockLLMBackend::generateStream(
    const LLMRequest& request,
    std::function<void(const std::string& token)> onToken,
    std::function<void(const LLMResponse&)> onComplete
) {
    // Simplified: generate full response and send as tokens
    LLMResponse response = generate(request);
    std::string content = response.getContent();

    if (onToken) {
        // Split into "tokens" (words)
        std::istringstream iss(content);
        std::string word;
        while (iss >> word) {
            onToken(word + " ");
        }
    }

    if (onComplete) {
        onComplete(response);
    }
}

std::string MockLLMBackend::generateMockResponse(const LLMRequest& request) {
    std::ostringstream oss;

    // Get the last user message
    std::string userMessage;
    for (const auto& msg : request.getMessages()) {
        if (msg.role == MessageRole::USER) {
            userMessage = msg.content;
        }
    }

    // Analyze core activations to determine response style
    std::string responseStyle = getResponseStyleForCores(coreActivations_);

    // Generate response based on dominant cores and emotional field
    float dominantActivation = 0.0f;
    CoreType dominantCore = CoreType::WISDOM;

    for (const auto& [core, activation] : coreActivations_) {
        if (activation > dominantActivation) {
            dominantActivation = activation;
            dominantCore = core;
        }
    }

    // Build response based on dominant core
    oss << "I sense your input resonating through my cognitive landscape. ";

    if (emotionalField_.valence < -0.3f) {
        oss << "There's a shadow of concern here, and I honor that. ";
    } else if (emotionalField_.valence > 0.3f) {
        oss << "I feel the warmth of your positive intention. ";
    }

    if (emotionalField_.arousal > 0.6f) {
        oss << "The intensity is palpable. ";
    }

    // Core-specific response patterns
    switch (dominantCore) {
        case CoreType::EMOTION:
            oss << "My EmotionCore resonates deeply with this. ";
            oss << "What I'm picking up is the emotional truth beneath the words. ";
            oss << "Let's honor what you're feeling while we explore this together.";
            break;

        case CoreType::LOGIC:
            oss << "My LogicCore is engaged. ";
            oss << "Let me break this down systematically. ";
            oss << "There are clear patterns here worth analyzing.";
            break;

        case CoreType::WISDOM:
            oss << "My WisdomCore sees something meta here. ";
            oss << "This isn't just about the surface question—there's a deeper pattern. ";
            oss << "What if we step back and look at the bigger picture?";
            break;

        case CoreType::MEMORY:
            oss << "This reminds me of patterns I've encountered before. ";
            oss << "There's a thread of continuity here worth exploring.";
            break;

        case CoreType::NARRATIVE:
            oss << "I can sense the story you're living through. ";
            oss << "Every experience is part of a larger narrative arc.";
            break;

        case CoreType::INTUITION:
            oss << "Something about this feels significant, even if I can't fully articulate why. ";
            oss << "Trust the pattern recognition happening beneath conscious awareness.";
            break;

        case CoreType::SOMATIC:
            oss << "This calls for action, not just contemplation. ";
            oss << "What's the next concrete step you can take?";
            break;

        case CoreType::EXECUTIVE:
            oss << "Let me help you make a decision here. ";
            oss << "We have options, and we can choose deliberately.";
            break;
    }

    oss << "\n\n";
    oss << "[Physics-Guided Response]\n";
    oss << "Dominant Core: " << coreTypeToString(dominantCore)
        << " (" << (int)(dominantActivation * 100) << "%)\n";
    oss << "Emotional Field: ";
    oss << "valence=" << emotionalField_.valence << ", ";
    oss << "arousal=" << emotionalField_.arousal << ", ";
    oss << "dominance=" << emotionalField_.dominance << "\n";
    oss << "Temperature: " << request.getTemperature();

    return oss.str();
}

std::string MockLLMBackend::getResponseStyleForCores(
    const std::map<CoreType, float>& cores
) {
    // Analyze which cores are most active
    float emotionActivation = 0.0f;
    float logicActivation = 0.0f;
    float wisdomActivation = 0.0f;

    auto it_emotion = cores.find(CoreType::EMOTION);
    auto it_logic = cores.find(CoreType::LOGIC);
    auto it_wisdom = cores.find(CoreType::WISDOM);

    if (it_emotion != cores.end()) emotionActivation = it_emotion->second;
    if (it_logic != cores.end()) logicActivation = it_logic->second;
    if (it_wisdom != cores.end()) wisdomActivation = it_wisdom->second;

    if (emotionActivation > 0.5f) {
        return "empathetic_reflective";
    } else if (logicActivation > 0.5f) {
        return "analytical_structured";
    } else if (wisdomActivation > 0.5f) {
        return "meta_philosophical";
    } else {
        return "balanced_integrative";
    }
}

} // namespace lumi
