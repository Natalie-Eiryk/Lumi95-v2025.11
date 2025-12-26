// Project: Lumi286
// Lumi286.cpp - Main entry point for Lumi286 OS

#include <iostream>
#include <../gui/Video_Pipeline/MainCRTWindow.h>
#include <lumi/physics/CodonPhysicsEngine.h>
#include <lumi/cores/EmotionCoreCPU.h>

#ifdef _WIN32
#include <io.h>
#include <fcntl.h>
#endif

// PhysX stub types (would normally come from PhysX headers)
namespace physx {
    typedef int PxErrorCode;

    // Stub classes for PhysX types
    class PxDefaultErrorCallback {};
    class PxDefaultAllocator {};
    class PxFoundation {};
    class PxPhysics {};
    class PxScene {};
    class PxMaterial {};

    struct PxVec3 {
        float x, y, z;
        PxVec3() : x(0), y(0), z(0) {}
        PxVec3(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {}
    };

    struct PxTolerancesScale {
        float length = 1.0f;
        float speed = 1.0f;
    };

    class PxSceneDesc {
    public:
        PxSceneDesc(const PxTolerancesScale& scale) {}
        PxVec3 gravity;
        void* cpuDispatcher;
        void* filterShader;
    };

    inline PxFoundation* PxCreateFoundation(int /*version*/, PxDefaultAllocator& /*alloc*/, PxDefaultErrorCallback& /*cb*/) { return nullptr; }
    inline PxPhysics* PxCreatePhysics(int /*version*/, PxFoundation& /*foundation*/, const PxTolerancesScale& /*scale*/) { return nullptr; }
    inline void* PxDefaultCpuDispatcherCreate(int /*numThreads*/) { return nullptr; }
    inline void* PxDefaultSimulationFilterShader = nullptr;

    const int PX_PHYSICS_VERSION = 0x05000000;
}

// Qt stub types (would normally come from Qt headers)
class QWidget {};
class QApplication {
public:
    QApplication(int& argc, char** argv) {
        // Stub implementation
    }
    int exec() {
        // Stub implementation - would run Qt event loop
        return 0;
    }
};

using namespace physx;

int main(int argc, char* argv[]) {
#ifdef _WIN32
    _setmode(_fileno(stdout), _O_TEXT);
#endif
    std::cout << "[🌌 Lumi286 Boot] Initializing system...\n";

    // === PhysX System Init (Stub) ===
    static PxDefaultErrorCallback gErrorCallback;
    static PxDefaultAllocator gAllocator;
    PxFoundation* foundation = PxCreateFoundation(PX_PHYSICS_VERSION, gAllocator, gErrorCallback);
    PxPhysics* physics = PxCreatePhysics(PX_PHYSICS_VERSION, *foundation, PxTolerancesScale());

    // Use braced initialization to avoid most vexing parse
    PxTolerancesScale tolerances{};
    PxSceneDesc sceneDesc{tolerances};
    sceneDesc.gravity = PxVec3(0, -9.81f, 0);
    sceneDesc.cpuDispatcher = PxDefaultCpuDispatcherCreate(2);
    sceneDesc.filterShader = PxDefaultSimulationFilterShader;

    PxScene* scene = nullptr; // Stub: would be physics->createScene(sceneDesc)
    PxMaterial* material = nullptr; // Stub: would be physics->createMaterial(0.5f, 0.5f, 0.6f)
    CodonPhysicsEngine* physicsEngine = new CodonPhysicsEngine(physics, scene, material);

    // ✅ Allocate and bind EmotionCoreCPU correctly
    EmotionCoreCPU* sharedEmotionCore = new EmotionCoreCPU();
    sharedEmotionCore->bindToPhysX(physics, scene, material);

    // 🧘 No synthetic codons injected — system will start blank
    // Ready for codon loading via UI or API


    // === Qt GUI Launch ===
    QApplication app(argc, argv);

    MainCRTWindow* window = new MainCRTWindow(physicsEngine);
    window->setEmotionCore(sharedEmotionCore);
    window->resize(1280, 720);
    window->show();

    std::cout << "[🌌 Lumi286] System initialized. GUI active.\n";

    return app.exec();
}
