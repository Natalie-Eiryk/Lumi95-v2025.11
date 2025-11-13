// Project: Lumi286
// Lumi286.cpp - Main entry point for Lumi286 OS

#include <../gui/Video_Pipeline/MainCRTWindow.h>




using namespace physx;

int main(int argc, char* argv[]) {
#ifdef _WIN32
    _setmode(_fileno(stdout), _O_TEXT);
#endif
    std::cout << "[🌌 Lumi286 Boot] Initializing system...\n";

    // === PhysX System Init ===
    static PxDefaultErrorCallback gErrorCallback;
    static PxDefaultAllocator gAllocator;
    PxFoundation* foundation = PxCreateFoundation(PX_PHYSICS_VERSION, gAllocator, gErrorCallback);
    PxPhysics* physics = PxCreatePhysics(PX_PHYSICS_VERSION, *foundation, PxTolerancesScale());

    PxSceneDesc sceneDesc(physics->getTolerancesScale());
    sceneDesc.gravity = PxVec3(0, -9.81f, 0);
    sceneDesc.cpuDispatcher = PxDefaultCpuDispatcherCreate(2);
    sceneDesc.filterShader = PxDefaultSimulationFilterShader;

    PxScene* scene = physics->createScene(sceneDesc);
    PxMaterial* material = physics->createMaterial(0.5f, 0.5f, 0.6f);
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


    return app.exec();
}
