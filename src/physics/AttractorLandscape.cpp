// AttractorLandscape.cpp - Physics implementation of cognitive attractors
#include <lumi/physics/AttractorLandscape.h>
#include <lumi/physics/PhysXStubs.h>
#include <cmath>
#include <random>
#include <algorithm>

using namespace physx;

namespace lumi {

// Map CoreType enum to string (for debugging)
const char* coreTypeToString(CoreType type) {
    switch (type) {
        case CoreType::EMOTION: return "EmotionCore";
        case CoreType::LOGIC: return "LogicCore";
        case CoreType::WISDOM: return "WisdomCore";
        case CoreType::MEMORY: return "MemoryCore";
        case CoreType::NARRATIVE: return "NarrativeCore";
        case CoreType::INTUITION: return "IntuitionCore";
        case CoreType::SOMATIC: return "SomaticCore";
        case CoreType::EXECUTIVE: return "ExecutiveCore";
        default: return "Unknown";
    }
}

// ============================================================
// CognitiveAttractor
// ============================================================

CognitiveAttractor::CognitiveAttractor()
    : position(0, 0, 0)
    , strength(1.0f)
    , radius(5.0f)
    , emotionalSignature()
    , coreType(CoreType::EMOTION)
    , active(true)
    , doctrineResonance(1.0f)
{}

CognitiveAttractor::CognitiveAttractor(const PxVec3& pos, float str, float rad,
                                      const EmotionalField& field, CoreType type)
    : position(pos)
    , strength(str)
    , radius(rad)
    , emotionalSignature(field)
    , coreType(type)
    , active(true)
    , doctrineResonance(1.0f)
{}

PxVec3 CognitiveAttractor::computeForce(const PxVec3& particlePos,
                                       const EmotionalField& particleCharge) const {
    if (!active) return PxVec3(0, 0, 0);

    // Vector from particle to attractor
    PxVec3 direction = position - particlePos;
    float distance = direction.magnitude();

    // Outside influence radius? No force
    if (distance > radius) return PxVec3(0, 0, 0);

    // Emotional resonance (similar emotions attract more)
    float emotionalResonance = 1.0f;

    // Valence similarity
    float valenceDiff = std::abs(emotionalSignature.valence - particleCharge.valence);
    float valenceSimilarity = 1.0f - valenceDiff;  // 0-1

    // Arousal similarity
    float arousalDiff = std::abs(emotionalSignature.arousal - particleCharge.arousal);
    float arousalSimilarity = 1.0f - arousalDiff;

    // Combined resonance (weighted average)
    emotionalResonance = (valenceSimilarity * 0.6f + arousalSimilarity * 0.4f);
    emotionalResonance = std::max(0.1f, emotionalResonance);  // Minimum 0.1

    // Force magnitude: inverse square law, modified by resonance
    float distanceSq = std::max(0.1f, distance * distance);  // Prevent division by zero
    float forceMagnitude = (strength * emotionalResonance * doctrineResonance) / distanceSq;

    // Direction normalized
    PxVec3 forceDirection = direction.getNormalized();

    return forceDirection * forceMagnitude;
}

// ============================================================
// CodonParticle
// ============================================================

CodonParticle::CodonParticle(PxRigidDynamic* body, const Codon& codon)
    : physicsBody_(body)
    , codonData_(codon)
    , emotionalCharge_(codon.getEmotionalField())
    , mass_(1.0f)
    , charge_(1.0f)
    , resonanceEnergy_(0.0f)
{}

CodonParticle::~CodonParticle() {
    // In real PhysX, would release the rigid body
    delete physicsBody_;
}

void CodonParticle::recordPosition(const PxVec3& pos) {
    trajectory_.push_back(pos);

    // Limit trajectory size
    if (trajectory_.size() > maxTrajectoryPoints_) {
        trajectory_.erase(trajectory_.begin());
    }
}

void CodonParticle::visitCore(CoreType core) {
    // Only record if not already visited
    if (std::find(visitedCores_.begin(), visitedCores_.end(), core) == visitedCores_.end()) {
        visitedCores_.push_back(core);
    }
}

bool CodonParticle::isNearAttractor(const CognitiveAttractor& attractor, float threshold) const {
    PxVec3 diff = physicsBody_->getGlobalPose() - attractor.position;
    return diff.magnitude() < threshold;
}

// ============================================================
// CollapseState
// ============================================================

CollapseState::CollapseState()
    : totalEnergy(0.0f)
    , particleCount(0)
    , isStable(false)
{}

CollapseState::LLMProbabilityBias CollapseState::toLLMBias() const {
    LLMProbabilityBias bias;

    bias.coreWeights = coreActivations;
    bias.emotionalField = dominantField;
    bias.primedSymbols = primedSymbols;

    // Temperature based on emotional arousal
    // Higher arousal = higher temperature (more creative/exploratory)
    bias.temperature = 0.7f + (dominantField.arousal * 0.3f);
    bias.temperature = std::clamp(bias.temperature, 0.3f, 1.2f);

    return bias;
}

// ============================================================
// AttractorLandscape
// ============================================================

AttractorLandscape::AttractorLandscape(PxPhysics* physics, PxScene* scene, PxMaterial* material)
    : physics_(physics)
    , scene_(scene)
    , material_(material)
    , simulationTime_(0.0f)
    , maxSimulationTime_(10.0f)
    , collapseThreshold_(0.05f)
{}

AttractorLandscape::~AttractorLandscape() {
    clear();
}

void AttractorLandscape::initializeCognitiveAttractors() {
    // Clear existing attractors
    attractors_.clear();

    // Define positions in 3D space (arranged in a sphere)
    const float radius = 5.0f;
    const float pi = 3.14159265359f;

    // EmotionCore - Front, slightly down (heart position)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, -1.0f, -radius),
        3.0f,  // Strong attractor
        4.0f,  // Large influence radius
        EmotionalField(0.0f, 0.7f, 0.5f),  // Neutral valence, high arousal
        CoreType::EMOTION
    ));

    // LogicCore - Top (head position)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, radius, 0.0f),
        2.5f,
        3.5f,
        EmotionalField(0.0f, 0.3f, 0.8f),  // Neutral, low arousal, high dominance
        CoreType::LOGIC
    ));

    // WisdomCore - Center (integration point)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, 0.0f, 0.0f),
        2.0f,
        6.0f,  // Large influence - draws everything in eventually
        EmotionalField(0.5f, 0.4f, 0.6f),  // Positive, calm, moderate dominance
        CoreType::WISDOM
    ));

    // MemoryCore - Back (past/memory position)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, -0.5f, radius),
        1.5f,
        3.0f,
        EmotionalField(0.0f, 0.2f, 0.3f),  // Neutral, very calm
        CoreType::MEMORY
    ));

    // NarrativeCore - Right (storytelling/expression)
    addAttractor(CognitiveAttractor(
        PxVec3(radius, 0.0f, 0.0f),
        1.8f,
        3.0f,
        EmotionalField(0.4f, 0.6f, 0.5f),  // Positive, moderate arousal
        CoreType::NARRATIVE
    ));

    // IntuitionCore - Left (non-verbal/implicit)
    addAttractor(CognitiveAttractor(
        PxVec3(-radius, 0.0f, 0.0f),
        1.5f,
        3.0f,
        EmotionalField(0.2f, 0.5f, 0.4f),
        CoreType::INTUITION
    ));

    // SomaticCore - Bottom (body/grounding)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, -radius, 0.0f),
        1.5f,
        3.0f,
        EmotionalField(0.0f, 0.4f, 0.7f),
        CoreType::SOMATIC
    ));

    // ExecutiveCore - Front-top (decision/action)
    addAttractor(CognitiveAttractor(
        PxVec3(0.0f, radius * 0.5f, -radius * 0.7f),
        2.0f,
        3.5f,
        EmotionalField(0.3f, 0.6f, 0.9f),  // Positive, aroused, high dominance
        CoreType::EXECUTIVE
    ));
}

void AttractorLandscape::addAttractor(const CognitiveAttractor& attractor) {
    attractors_.push_back(attractor);
}

void AttractorLandscape::removeAttractor(CoreType core) {
    attractors_.erase(
        std::remove_if(attractors_.begin(), attractors_.end(),
            [core](const CognitiveAttractor& a) { return a.coreType == core; }),
        attractors_.end()
    );
}

void AttractorLandscape::setAttractorActive(CoreType core, bool active) {
    for (auto& attractor : attractors_) {
        if (attractor.coreType == core) {
            attractor.active = active;
        }
    }
}

CodonParticle* AttractorLandscape::spawnCodon(const Codon& codon,
                                             const PxVec3& position,
                                             const PxVec3& velocity) {
    // Create PhysX rigid body (stub for now)
    PxRigidDynamic* body = new PxRigidDynamic();
    body->setGlobalPose(position);
    body->setLinearVelocity(velocity);
    body->mass = 1.0f;

    // Create codon particle wrapper
    CodonParticle* particle = new CodonParticle(body, codon);
    particle->setMass(1.0f);
    particle->setEmotionalCharge(codon.getEmotionalField());

    particles_.push_back(std::unique_ptr<CodonParticle>(particle));

    return particle;
}

CodonParticle* AttractorLandscape::spawnCodonAtCenter(const Codon& codon, float velocityMagnitude) {
    PxVec3 centerPos(0.0f, 0.0f, 0.0f);
    PxVec3 randomVel = randomDirection() * velocityMagnitude;

    return spawnCodon(codon, centerPos, randomVel);
}

void AttractorLandscape::step(float deltaTime) {
    simulationTime_ += deltaTime;

    // Apply forces from attractors
    applyAttractorForces();

    // Integrate physics (simple Euler integration)
    for (auto& particle : particles_) {
        particle->getPhysicsBody()->integrate(deltaTime);

        // Record trajectory
        particle->recordPosition(particle->getPhysicsBody()->getGlobalPose());
    }

    // Update particle trajectories and detect core visits
    updateParticleTrajectories();
    detectCoreVisits();
}

bool AttractorLandscape::hasCollapsed() const {
    // System has collapsed if:
    // 1. Total kinetic energy is below threshold
    // 2. Simulation has run for minimum time

    if (simulationTime_ < 0.5f) return false;  // Minimum 0.5 seconds

    float energy = getSystemEnergy();
    return energy < collapseThreshold_;
}

float AttractorLandscape::getSystemEnergy() const {
    return computeTotalKineticEnergy();
}

CollapseState AttractorLandscape::getCollapseState() const {
    CollapseState state;

    state.particleCount = particles_.size();
    state.totalEnergy = getSystemEnergy();
    state.isStable = hasCollapsed();

    // Compute core activations based on particle proximity
    std::map<CoreType, int> coreVisits;
    std::map<CoreType, float> coreProximity;

    for (const auto& particle : particles_) {
        PxVec3 particlePos = particle->getPhysicsBody()->getGlobalPose();

        // Check proximity to each attractor
        for (const auto& attractor : attractors_) {
            float distance = (particlePos - attractor.position).magnitude();
            float proximity = std::max(0.0f, 1.0f - (distance / attractor.radius));

            coreProximity[attractor.coreType] += proximity;
        }

        // Add visited cores
        for (auto core : particle->getVisitedCores()) {
            coreVisits[core]++;
        }
    }

    // Normalize to 0-1
    float maxProximity = 0.0001f;
    for (const auto& [core, prox] : coreProximity) {
        maxProximity = std::max(maxProximity, prox);
    }

    for (const auto& [core, prox] : coreProximity) {
        state.coreActivations[core] = prox / maxProximity;
    }

    // Compute dominant emotional field (average of all particles)
    EmotionalField totalField(0, 0, 0);
    for (const auto& particle : particles_) {
        auto field = particle->getEmotionalCharge();
        totalField.valence += field.valence;
        totalField.arousal += field.arousal;
        totalField.dominance += field.dominance;
    }

    if (!particles_.empty()) {
        float count = static_cast<float>(particles_.size());
        totalField.valence /= count;
        totalField.arousal /= count;
        totalField.dominance /= count;
    }

    state.dominantField = totalField;

    // Collect primed symbols from particles
    for (const auto& particle : particles_) {
        std::string symbol = particle->getCodon().getSymbol();
        if (!symbol.empty() &&
            std::find(state.primedSymbols.begin(), state.primedSymbols.end(), symbol) == state.primedSymbols.end()) {
            state.primedSymbols.push_back(symbol);
        }
    }

    return state;
}

void AttractorLandscape::clear() {
    particles_.clear();
    simulationTime_ = 0.0f;
}

EmotionalField AttractorLandscape::computeEmotionalFieldAt(const PxVec3& position) const {
    // Compute weighted average of attractor emotional signatures
    // Weight by inverse distance

    EmotionalField field(0, 0, 0);
    float totalWeight = 0.0f;

    for (const auto& attractor : attractors_) {
        if (!attractor.active) continue;

        float distance = (position - attractor.position).magnitude();
        float weight = 1.0f / std::max(0.1f, distance);

        field.valence += attractor.emotionalSignature.valence * weight;
        field.arousal += attractor.emotionalSignature.arousal * weight;
        field.dominance += attractor.emotionalSignature.dominance * weight;

        totalWeight += weight;
    }

    if (totalWeight > 0.0f) {
        field.valence /= totalWeight;
        field.arousal /= totalWeight;
        field.dominance /= totalWeight;
    }

    return field;
}

// Private helpers

PxVec3 AttractorLandscape::randomDirection() const {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_real_distribution<float> dist(-1.0f, 1.0f);

    PxVec3 dir(dist(gen), dist(gen), dist(gen));
    return dir.getNormalized();
}

float AttractorLandscape::computeTotalKineticEnergy() const {
    float totalEnergy = 0.0f;

    for (const auto& particle : particles_) {
        PxVec3 vel = particle->getPhysicsBody()->getLinearVelocity();
        float speed = vel.magnitude();
        float mass = particle->getMass();

        // KE = 0.5 * m * v²
        totalEnergy += 0.5f * mass * speed * speed;
    }

    return totalEnergy;
}

void AttractorLandscape::applyAttractorForces() {
    for (auto& particle : particles_) {
        PxVec3 particlePos = particle->getPhysicsBody()->getGlobalPose();
        EmotionalField particleCharge = particle->getEmotionalCharge();

        // Compute total force from all attractors
        PxVec3 totalForce(0, 0, 0);

        for (const auto& attractor : attractors_) {
            PxVec3 force = attractor.computeForce(particlePos, particleCharge);
            totalForce = totalForce + force;
        }

        // Apply damping (energy dissipation)
        PxVec3 vel = particle->getPhysicsBody()->getLinearVelocity();
        PxVec3 dampingForce = vel * -0.1f;  // 10% damping
        totalForce = totalForce + dampingForce;

        // Add force to particle
        particle->getPhysicsBody()->addForce(totalForce);
    }
}

void AttractorLandscape::updateParticleTrajectories() {
    for (auto& particle : particles_) {
        // Already done in step() via recordPosition
    }
}

void AttractorLandscape::detectCoreVisits() {
    const float visitThreshold = 2.0f;  // Within 2 units = "visited"

    for (auto& particle : particles_) {
        for (const auto& attractor : attractors_) {
            if (particle->isNearAttractor(attractor, visitThreshold)) {
                particle->visitCore(attractor.coreType);
            }
        }
    }
}

} // namespace lumi
