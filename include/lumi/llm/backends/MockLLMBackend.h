// MockLLMBackend.h - Simple mock LLM for testing physics-guided responses
#pragma once

#include <lumi/base/ILLMBackend.h>
#include <lumi/base/LLMRequest.h>
#include <lumi/base/LLMResponse.h>
#include <lumi/orchestrator/MultiLLMRouter.h>
#include <string>
#include <map>

namespace lumi {

// Simple mock LLM that generates responses based on core activations
// This demonstrates how physics collapse state influences LLM behavior
class MockLLMBackend : public ILLMBackend {
public:
    MockLLMBackend(const std::string& modelName = "mock-luminara-v1");
    ~MockLLMBackend() override = default;

    // Synchronous inference
    LLMResponse generate(const LLMRequest& request) override;

    // Async (simplified - just calls generate synchronously)
    void generateAsync(
        const LLMRequest& request,
        std::function<void(const LLMResponse&)> callback
    ) override;

    // Stream (simplified - generates all at once)
    void generateStream(
        const LLMRequest& request,
        std::function<void(const std::string& token)> onToken,
        std::function<void(const LLMResponse&)> onComplete
    ) override;

    // Backend information
    std::string getBackendName() const override { return "MockLLM"; }
    std::string getModelName() const override { return modelName_; }
    bool isAvailable() const override { return true; }

    // Configuration
    void setTemperature(float temp) override { temperature_ = temp; }
    void setMaxTokens(int maxTokens) override { maxTokens_ = maxTokens; }
    void setSystemPrompt(const std::string& prompt) override { systemPrompt_ = prompt; }

    // Health check
    bool healthCheck() override { return true; }

    // Mock-specific: set core activations for response generation
    void setCoreActivations(const std::map<CoreType, float>& activations) {
        coreActivations_ = activations;
    }

    void setEmotionalField(const EmotionalField& field) {
        emotionalField_ = field;
    }

private:
    std::string generateMockResponse(const LLMRequest& request);
    std::string getResponseStyleForCores(const std::map<CoreType, float>& cores);

    std::string modelName_;
    float temperature_;
    int maxTokens_;
    std::string systemPrompt_;
    std::map<CoreType, float> coreActivations_;
    EmotionalField emotionalField_;
};

} // namespace lumi
