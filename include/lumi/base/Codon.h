// Codon.h - Fundamental unit of cognitive information in Luminara
#pragma once

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <chrono>

namespace lumi {

// Codon types
enum class CodonType {
    EMOTIONAL,      // Emotional state (EMOT_CURIOSITY, EMOT_FOCUS, etc.)
    LOGICAL,        // Logical reasoning step
    NARRATIVE,      // Story/narrative fragment
    MEMORY,         // Memory reference
    SENSORY,        // Sensory input
    MOTOR,          // Action/motor output
    META,           // Meta-cognitive reflection
    SYMBOLIC        // Pure symbolic/abstract
};

// Emotional valence and arousal
struct EmotionalField {
    float valence;      // -1 (negative) to +1 (positive)
    float arousal;      // 0 (calm) to 1 (intense)
    float dominance;    // 0 (submissive) to 1 (dominant)

    EmotionalField() : valence(0.0f), arousal(0.0f), dominance(0.0f) {}
    EmotionalField(float v, float a, float d) : valence(v), arousal(a), dominance(d) {}
};

// Core Codon class
class Codon {
public:
    Codon();
    Codon(CodonType type, const std::string& content);

    // Core properties
    CodonType getType() const { return type_; }
    std::string getContent() const { return content_; }
    std::string getSymbol() const { return symbol_; }

    void setContent(const std::string& content) { content_ = content; }
    void setSymbol(const std::string& symbol) { symbol_ = symbol; }

    // Emotional properties
    EmotionalField getEmotionalField() const { return emotionalField_; }
    void setEmotionalField(const EmotionalField& field) { emotionalField_ = field; }
    void setEmotionalField(float valence, float arousal, float dominance) {
        emotionalField_ = EmotionalField(valence, arousal, dominance);
    }

    // Phase and resonance (for À/e compression)
    float getPhase() const { return phase_; }
    void setPhase(float phase) { phase_ = phase; }

    float getResonance() const { return resonance_; }
    void setResonance(float resonance) { resonance_ = resonance; }

    // Metadata
    void setMetadata(const std::string& key, const std::string& value) {
        metadata_[key] = value;
    }
    std::string getMetadata(const std::string& key) const {
        auto it = metadata_.find(key);
        return (it != metadata_.end()) ? it->second : "";
    }

    // Timestamp
    std::chrono::system_clock::time_point getTimestamp() const { return timestamp_; }

    // Source tracking (which core created this)
    void setSource(const std::string& source) { source_ = source; }
    std::string getSource() const { return source_; }

    // Serialization
    std::string toJson() const;
    static Codon fromJson(const std::string& json);

private:
    CodonType type_;
    std::string content_;       // Semantic content
    std::string symbol_;        // Symbolic identifier (e.g., "EMOT_CURIOSITY")
    EmotionalField emotionalField_;
    float phase_;               // Phase position in emotional waveform (0-2À)
    float resonance_;           // Resonance strength (0-1)
    std::map<std::string, std::string> metadata_;
    std::chrono::system_clock::time_point timestamp_;
    std::string source_;        // Which core created this codon
};

// Codon Bundle - collection of related codons
class CodonBundle {
public:
    CodonBundle() = default;

    void addCodon(const Codon& codon);
    void addCodon(Codon&& codon);

    const std::vector<Codon>& getCodons() const { return codons_; }
    size_t size() const { return codons_.size(); }
    bool empty() const { return codons_.empty(); }

    // Get average emotional field of all codons
    EmotionalField getAverageEmotionalField() const;

    // Filter codons by type
    std::vector<Codon> getCodonsByType(CodonType type) const;

    void clear() { codons_.clear(); }

private:
    std::vector<Codon> codons_;
    std::chrono::system_clock::time_point creationTime_;
};

} // namespace lumi
