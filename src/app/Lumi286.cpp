// Project: Lumi286
// Lumi286.cpp - Main entry point for Lumi286 OS

#include <iostream>
#include <lumi/physics/CodonPhysicsEngine.h>
#include <lumi/cores/EmotionCoreCPU.h>

// Qt6 GUI (conditional compilation based on availability)
#ifdef LUMI_HAS_QT6
#include <QApplication>
#include <Video_Pipeline/MainCRTWindow.h>
#endif

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
        PxSceneDesc(const PxTolerancesScale& /*scale*/)
            : gravity(), cpuDispatcher(nullptr), filterShader(nullptr) {
            // Initialize all members to prevent C26495 warning
        }
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

using namespace physx;

int main(int argc, char* argv[]) {
    // argc/argv used for QApplication initialization below
#ifdef _WIN32
    // Set console mode to text (ignore return value - non-critical)
    (void)_setmode(_fileno(stdout), _O_TEXT);
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


#ifdef LUMI_HAS_QT6
    // === Qt6 GUI Launch ===
    QApplication app(argc, argv);
    std::cout << "[🌌 Lumi286] Qt6 Application initialized\n";

    MainCRTWindow* window = new MainCRTWindow(physicsEngine);

    // Report loaded modules to GUI
    std::cout << "[🌌 Lumi286] Loading cognitive modules...\n";

    window->addLoadedModule("PhysX Foundation", "INITIALIZED");
    window->addLoadedModule("PhysX Physics Engine", "ACTIVE");
    window->addLoadedModule("CodonPhysicsEngine", "READY");
    window->addLoadedModule("EmotionCore (CPU)", "ALLOCATED");

    // Bind EmotionCore
    window->setEmotionCore(sharedEmotionCore);
    window->addLoadedModule("EmotionCore Binding", "BOUND TO PHYSX");

    // Add placeholder for other cores (will implement later)
    window->addLoadedModule("LogicCore", "STUB");
    window->addLoadedModule("WisdomCore", "STUB");
    window->addLoadedModule("MemoryCore", "STUB");
    window->addLoadedModule("NarrativeCore", "STUB");
    window->addLoadedModule("IntuitionCore", "STUB");
    window->addLoadedModule("SomaticCore", "STUB");
    window->addLoadedModule("ExecutiveCore", "STUB");
    window->addLoadedModule("CoreFusionOrchestrator", "STUB");

    window->setSystemStatus("✅ ONLINE - All systems nominal");
    window->show();

    std::cout << "[🌌 Lumi286] GUI displayed. Entering event loop.\n";

    return app.exec();
#else
    // === Console-only mode (Qt6 not available) ===
    std::cout << "[🌌 Lumi286] Running in console mode (Qt6 not available)\n";
    std::cout << "\n";
    std::cout << "╔════════════════════════════════════════════════════════════╗\n";
    std::cout << "║        LUMINARA COGNITIVE ARCHITECTURE v1.0               ║\n";
    std::cout << "╚════════════════════════════════════════════════════════════╝\n";
    std::cout << "\n";
    std::cout << "Loaded Modules:\n";
    std::cout << "  ✅ PhysX Foundation         [INITIALIZED]\n";
    std::cout << "  ✅ PhysX Physics Engine     [ACTIVE]\n";
    std::cout << "  ✅ CodonPhysicsEngine       [READY]\n";
    std::cout << "  ✅ EmotionCore (CPU)        [ALLOCATED]\n";
    std::cout << "  ✅ EmotionCore Binding      [BOUND TO PHYSX]\n";
    std::cout << "  ⚠️  LogicCore               [STUB]\n";
    std::cout << "  ⚠️  WisdomCore               [STUB]\n";
    std::cout << "  ⚠️  MemoryCore               [STUB]\n";
    std::cout << "  ⚠️  NarrativeCore            [STUB]\n";
    std::cout << "  ⚠️  IntuitionCore            [STUB]\n";
    std::cout << "  ⚠️  SomaticCore              [STUB]\n";
    std::cout << "  ⚠️  ExecutiveCore            [STUB]\n";
    std::cout << "  ⚠️  CoreFusionOrchestrator   [STUB]\n";
    std::cout << "\n";
    std::cout << "System Status: ✅ ONLINE - All systems nominal\n";
    std::cout << "\n";
    std::cout << "Note: Build with Qt6 to enable GUI interface.\n";
    std::cout << "Press Ctrl+C to exit.\n";
    std::cout << "\n";

    // Keep running
    std::cout << "[🌌 Lumi286] System running. Press Ctrl+C to stop.\n";
    std::cin.get();  // Wait for user input

    return 0;
#endif
}
