// Codon.cpp - Implementation of Codon and CodonBundle
#include <lumi/base/Codon.h>

namespace lumi {

// ============================================================
// Codon
// ============================================================

Codon::Codon()
    : type_(CodonType::SYMBOLIC)
    , content_("")
    , symbol_("")
    , emotionalField_()
    , phase_(0.0f)
    , resonance_(0.0f)
    , timestamp_(std::chrono::system_clock::now())
    , source_("")
{}

Codon::Codon(CodonType type, const std::string& content)
    : type_(type)
    , content_(content)
    , symbol_("")
    , emotionalField_()
    , phase_(0.0f)
    , resonance_(0.0f)
    , timestamp_(std::chrono::system_clock::now())
    , source_("")
{}

std::string Codon::toJson() const {
    // Simplified JSON serialization (would use nlohmann::json in production)
    std::string json = "{";
    json += "\"type\":\"" + std::to_string(static_cast<int>(type_)) + "\",";
    json += "\"content\":\"" + content_ + "\",";
    json += "\"symbol\":\"" + symbol_ + "\",";
    json += "\"valence\":" + std::to_string(emotionalField_.valence) + ",";
    json += "\"arousal\":" + std::to_string(emotionalField_.arousal) + ",";
    json += "\"dominance\":" + std::to_string(emotionalField_.dominance) + ",";
    json += "\"phase\":" + std::to_string(phase_) + ",";
    json += "\"resonance\":" + std::to_string(resonance_);
    json += "}";
    return json;
}

Codon Codon::fromJson(const std::string& json) {
    // Stub implementation - would use nlohmann::json in production
    Codon codon;
    return codon;
}

// ============================================================
// CodonBundle
// ============================================================

void CodonBundle::addCodon(const Codon& codon) {
    codons_.push_back(codon);
}

void CodonBundle::addCodon(Codon&& codon) {
    codons_.push_back(std::move(codon));
}

EmotionalField CodonBundle::getAverageEmotionalField() const {
    if (codons_.empty()) {
        return EmotionalField(0.0f, 0.0f, 0.0f);
    }

    float totalValence = 0.0f;
    float totalArousal = 0.0f;
    float totalDominance = 0.0f;

    for (const auto& codon : codons_) {
        auto field = codon.getEmotionalField();
        totalValence += field.valence;
        totalArousal += field.arousal;
        totalDominance += field.dominance;
    }

    float count = static_cast<float>(codons_.size());
    return EmotionalField(
        totalValence / count,
        totalArousal / count,
        totalDominance / count
    );
}

std::vector<Codon> CodonBundle::getCodonsByType(CodonType type) const {
    std::vector<Codon> filtered;
    for (const auto& codon : codons_) {
        if (codon.getType() == type) {
            filtered.push_back(codon);
        }
    }
    return filtered;
}

} // namespace lumi
