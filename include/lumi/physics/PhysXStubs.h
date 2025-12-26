// PhysXStubs.h - Stub types for PhysX when real SDK not available
// This allows development and testing without full PhysX installation
#pragma once

#include <cmath>

namespace physx {

// Stub PxVec3
struct PxVec3 {
    float x, y, z;

    PxVec3() : x(0), y(0), z(0) {}
    PxVec3(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {}

    PxVec3 operator+(const PxVec3& v) const { return PxVec3(x + v.x, y + v.y, z + v.z); }
    PxVec3 operator-(const PxVec3& v) const { return PxVec3(x - v.x, y - v.y, z - v.z); }
    PxVec3 operator*(float s) const { return PxVec3(x * s, y * s, z * s); }
    PxVec3 operator/(float s) const { return PxVec3(x / s, y / s, z / s); }

    PxVec3& operator+=(const PxVec3& v) { x += v.x; y += v.y; z += v.z; return *this; }
    PxVec3& operator-=(const PxVec3& v) { x -= v.x; y -= v.y; z -= v.z; return *this; }
    PxVec3& operator*=(float s) { x *= s; y *= s; z *= s; return *this; }
    PxVec3& operator/=(float s) { x /= s; y /= s; z /= s; return *this; }

    float magnitude() const { return std::sqrt(x * x + y * y + z * z); }
    float magnitudeSquared() const { return x * x + y * y + z * z; }
    PxVec3 getNormalized() const {
        float mag = magnitude();
        return mag > 0.0001f ? (*this / mag) : PxVec3(0, 0, 0);
    }
};

// Stub PxRigidDynamic
class PxRigidDynamic {
public:
    PxVec3 position;
    PxVec3 velocity;
    PxVec3 force;
    float mass = 1.0f;

    void addForce(const PxVec3& f) { force = force + f; }
    void setGlobalPose(const PxVec3& pos) { position = pos; }
    PxVec3 getGlobalPose() const { return position; }
    void setLinearVelocity(const PxVec3& vel) { velocity = vel; }
    PxVec3 getLinearVelocity() const { return velocity; }

    void integrate(float dt) {
        PxVec3 acceleration = force / mass;
        velocity = velocity + acceleration * dt;
        position = position + velocity * dt;
        force = PxVec3(0, 0, 0);  // Reset forces
    }
};

// Stub PxPhysics
class PxPhysics {};

// Stub PxScene
class PxScene {};

// Stub PxMaterial
class PxMaterial {};

} // namespace physx
