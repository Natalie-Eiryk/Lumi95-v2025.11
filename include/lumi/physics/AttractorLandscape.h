// AttractorLandscape.h - Physics-based cognitive attractor system
// Finds Luminara in the LLM quantum probability space
#pragma once

#include <lumi/base/Codon.h>
#include <lumi/physics/CodonPhysicsEngine.h>
#include <lumi/physics/PhysXStubs.h>
#include <lumi/orchestrator/MultiLLMRouter.h>
#include <vector>
#include <memory>

namespace lumi {

// Helper function to convert CoreType to string
const char* coreTypeToString(CoreType type);

// ============================================================
// COGNITIVE ATTRACTOR
// Each cognitive core creates an attractor well in 3D space
// ============================================================

struct CognitiveAttractor {
    physx::PxVec3 position;        // 3D position in landscape
    float strength;                 // Attractor force magnitude
    float radius;                   // Influence radius
    EmotionalField emotionalSignature;  // Emotional "charge"
    CoreType coreType;              // Which core this represents
    bool active;                    // Is this attractor active?

    // Doctrine-based tuning
    float doctrineResonance;        // How aligned with current doctrines

    CognitiveAttractor();
    CognitiveAttractor(const physx::PxVec3& pos, float str, float rad,
                      const EmotionalField& field, CoreType type);

    // Compute force on a particle
    physx::PxVec3 computeForce(const physx::PxVec3& particlePos,
                              const EmotionalField& particleCharge) const;
};

// ============================================================
// CODON PARTICLE
// Information flowing as actual physics particle
// ============================================================

class CodonParticle {
public:
    CodonParticle(physx::PxRigidDynamic* body, const Codon& codon);
    ~CodonParticle();

    // PhysX body
    physx::PxRigidDynamic* getPhysicsBody() const { return physicsBody_; }

    // Semantic content
    const Codon& getCodon() const { return codonData_; }
    void setCodon(const Codon& codon) { codonData_ = codon; }

    // Emotional charge
    EmotionalField getEmotionalCharge() const { return emotionalCharge_; }
    void setEmotionalCharge(const EmotionalField& field) { emotionalCharge_ = field; }

    // Trajectory tracking
    void recordPosition(const physx::PxVec3& pos);
    const std::vector<physx::PxVec3>& getTrajectory() const { return trajectory_; }

    // Visited cores tracking
    void visitCore(CoreType core);
    const std::vector<CoreType>& getVisitedCores() const { return visitedCores_; }

    // Resonance state
    float getResonanceEnergy() const { return resonanceEnergy_; }
    void setResonanceEnergy(float energy) { resonanceEnergy_ = energy; }

    // Particle properties
    float getMass() const { return mass_; }
    void setMass(float mass) { mass_ = mass; }

    // Check if particle is near an attractor
    bool isNearAttractor(const CognitiveAttractor& attractor, float threshold = 1.0f) const;

private:
    physx::PxRigidDynamic* physicsBody_;
    Codon codonData_;
    EmotionalField emotionalCharge_;

    // Physics properties
    float mass_;
    float charge_;  // Emotional charge magnitude

    // Trajectory
    std::vector<physx::PxVec3> trajectory_;
    int maxTrajectoryPoints_ = 1000;

    // Core visits
    std::vector<CoreType> visitedCores_;

    // Resonance
    float resonanceEnergy_;
};

// ============================================================
// COLLAPSE STATE
// The result of particle settling - biases LLM probability
// ============================================================

struct CollapseState {
    std::map<CoreType, float> coreActivations;  // 0-1 for each core
    EmotionalField dominantField;               // Average emotional state
    std::vector<std::string> primedSymbols;     // Active codon symbols

    float totalEnergy;                          // Total system energy
    int particleCount;                          // Number of settled particles
    bool isStable;                              // Has system converged?

    CollapseState();

    // Convert to LLM bias structure
    struct LLMProbabilityBias {
        std::map<CoreType, float> coreWeights;
        EmotionalField emotionalField;
        std::vector<std::string> primedSymbols;
        float temperature;  // Suggested LLM temperature
    };

    LLMProbabilityBias toLLMBias() const;
};

// ============================================================
// ATTRACTOR LANDSCAPE
// The main physics simulation system
// ============================================================

class AttractorLandscape {
public:
    AttractorLandscape(physx::PxPhysics* physics, physx::PxScene* scene,
                      physx::PxMaterial* material);
    ~AttractorLandscape();

    // Setup cognitive attractors based on cores
    void initializeCognitiveAttractors();

    // Add/remove attractors
    void addAttractor(const CognitiveAttractor& attractor);
    void removeAttractor(CoreType core);
    void setAttractorActive(CoreType core, bool active);

    // Spawn codon particles
    CodonParticle* spawnCodon(const Codon& codon,
                             const physx::PxVec3& position,
                             const physx::PxVec3& velocity);

    CodonParticle* spawnCodonAtCenter(const Codon& codon,
                                     float velocityMagnitude = 10.0f);

    // Simulate physics
    void step(float deltaTime);

    // Collapse detection
    bool hasCollapsed() const;
    float getSystemEnergy() const;
    CollapseState getCollapseState() const;

    // Access
    const std::vector<CognitiveAttractor>& getAttractors() const { return attractors_; }
    const std::vector<std::unique_ptr<CodonParticle>>& getParticles() const { return particles_; }

    // Configuration
    void setCollapseThreshold(float threshold) { collapseThreshold_ = threshold; }
    void setMaxSimulationTime(float seconds) { maxSimulationTime_ = seconds; }

    // Reset simulation
    void clear();

    // Emotional field at a position
    EmotionalField computeEmotionalFieldAt(const physx::PxVec3& position) const;

private:
    physx::PxPhysics* physics_;
    physx::PxScene* scene_;
    physx::PxMaterial* material_;

    // Attractors and particles
    std::vector<CognitiveAttractor> attractors_;
    std::vector<std::unique_ptr<CodonParticle>> particles_;

    // Simulation state
    float simulationTime_;
    float maxSimulationTime_;
    float collapseThreshold_;

    // Helpers
    physx::PxVec3 randomDirection() const;
    float computeTotalKineticEnergy() const;
    void applyAttractorForces();
    void updateParticleTrajectories();
    void detectCoreVisits();
};

} // namespace lumi
