// MultiLLMRouter.h - Routes requests to different LLM backends based on cognitive function
#pragma once

#include <lumi/base/ILLMBackend.h>
#include <lumi/base/Codon.h>
#include <map>
#include <memory>
#include <string>

namespace lumi {

// Cognitive core types
enum class CoreType {
    EMOTION,      // Emotional processing
    LOGIC,        // Logical reasoning
    WISDOM,       // Meta-cognitive synthesis
    MEMORY,       // Recall and retrieval
    NARRATIVE,    // Story construction
    INTUITION,    // Pattern recognition
    SOMATIC,      // Action/embodied cognition
    EXECUTIVE     // Decision-making and control
};

// Convert string to CoreType
CoreType stringToCoreType(const std::string& str);

// Multi-LLM routing system
class MultiLLMRouter {
public:
    MultiLLMRouter() = default;
    ~MultiLLMRouter() = default;

    // Register LLM backend for specific core
    void registerBackend(CoreType core, std::unique_ptr<ILLMBackend> backend);

    // Register backend by name (string version)
    void registerBackend(const std::string& coreName, std::unique_ptr<ILLMBackend> backend);

    // Get backend for specific core
    ILLMBackend* getBackend(CoreType core);
    ILLMBackend* getBackend(const std::string& coreName);

    // Set fallback backend (used when no specific backend registered)
    void setDefaultBackend(std::unique_ptr<ILLMBackend> backend);
    ILLMBackend* getDefaultBackend() { return defaultBackend_.get(); }

    // Auto-route based on codon type
    ILLMBackend* routeByCodon(const Codon& codon);

    // Auto-route based on message content analysis
    ILLMBackend* routeByContent(const std::string& content);

    // Load configuration from YAML file
    bool loadConfig(const std::string& configPath);

    // Get statistics
    struct BackendStats {
        int requestCount = 0;
        int64_t totalLatencyMs = 0;
        int errorCount = 0;
        float avgLatency() const {
            return requestCount > 0 ? (float)totalLatencyMs / requestCount : 0.0f;
        }
    };

    BackendStats getStats(CoreType core) const;
    void recordRequest(CoreType core, int64_t latencyMs, bool error = false);

    // Health check all backends
    bool healthCheckAll();

    // List available backends
    std::vector<std::pair<CoreType, std::string>> listBackends() const;

private:
    std::map<CoreType, std::unique_ptr<ILLMBackend>> backends_;
    std::unique_ptr<ILLMBackend> defaultBackend_;
    std::map<CoreType, BackendStats> stats_;

    // Helper: detect emotional content
    bool hasEmotionalContent(const std::string& text) const;
    // Helper: detect logical/analytical content
    bool hasLogicalContent(const std::string& text) const;
    // Helper: detect narrative content
    bool hasNarrativeContent(const std::string& text) const;
};

} // namespace lumi
