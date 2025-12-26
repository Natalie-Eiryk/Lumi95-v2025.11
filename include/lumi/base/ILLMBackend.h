// ILLMBackend.h - Interface for LLM backends in Luminara
#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>
#include "Codon.h"

namespace lumi {

// Forward declarations
class LLMRequest;
class LLMResponse;

// LLM Backend Interface
class ILLMBackend {
public:
    virtual ~ILLMBackend() = default;

    // Synchronous inference
    virtual LLMResponse generate(const LLMRequest& request) = 0;

    // Asynchronous inference with callback
    virtual void generateAsync(
        const LLMRequest& request,
        std::function<void(const LLMResponse&)> callback
    ) = 0;

    // Stream generation (for real-time responses)
    virtual void generateStream(
        const LLMRequest& request,
        std::function<void(const std::string& token)> onToken,
        std::function<void(const LLMResponse&)> onComplete
    ) = 0;

    // Backend information
    virtual std::string getBackendName() const = 0;
    virtual std::string getModelName() const = 0;
    virtual bool isAvailable() const = 0;

    // Configuration
    virtual void setTemperature(float temp) = 0;
    virtual void setMaxTokens(int maxTokens) = 0;
    virtual void setSystemPrompt(const std::string& prompt) = 0;

    // Health check
    virtual bool healthCheck() = 0;
};

} // namespace lumi
