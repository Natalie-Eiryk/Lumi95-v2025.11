# Lumi286 Source Build Configuration

# Create base library
add_library(lumi_base
    base/Codon.cpp
    base/CodonFidelityAnalyzer.cpp
    base/CodonGroup.cpp
    base/CognitiveBlackboard.cpp
    base/Doctrine.cpp
    base/LLMRouter.cpp
)

target_include_directories(lumi_base PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

# Apply environment variables to base library
lumi_apply_env_to_target(lumi_base
    INCLUDE_VARS TENSORRT_INCLUDE_DIRS PHYSX_INCLUDE_DIRS
    LIB_VARS     TENSORRT_LIBRARY_DIRS PHYSX_LIBRARY_DIRS
    DEFINE_VARS  LUMI_RUN_MODE LUMI_ENV
)

# Create cores library
add_library(lumi_cores
    cores/EmotionCore.cpp
    cores/ExecutiveCore.cpp
    cores/IntuitionCore.cpp
    cores/LogicCore.cpp
    cores/MemoryCore.cpp
    cores/NarrativeCore.cpp
    cores/SomaticCore.cpp
    cores/WisdomCore.cpp
)

target_include_directories(lumi_cores PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(lumi_cores PUBLIC lumi_base)

# Create orchestrator library
add_library(lumi_orchestrator
    orchestrator/CoreFusionOrchestrator.cpp
)

target_include_directories(lumi_orchestrator PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(lumi_orchestrator PUBLIC lumi_cores)

# Create LLM backends library
add_library(lumi_llm
    llm/backends/HFBackend.cpp
    llm/backends/PythonProxyBackend.cpp
    llm/backends/TensorRTBackend.cpp
)

target_include_directories(lumi_llm PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(lumi_llm PUBLIC lumi_base)

# Link TensorRT if found
if(TensorRT_FOUND)
    target_link_libraries(lumi_llm PUBLIC TensorRT::nvinfer)
    if(TARGET TensorRT::nvinfer_plugin)
        target_link_libraries(lumi_llm PUBLIC TensorRT::nvinfer_plugin)
    endif()
endif()

# Create interop library
add_library(lumi_interop
    interop/PythonBridge.cpp
    interop/QtUI.cpp
)

target_include_directories(lumi_interop PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(lumi_interop PUBLIC lumi_base)

# Link Qt6 if found
if(Qt6_FOUND)
    target_link_libraries(lumi_interop PUBLIC Qt6::Widgets Qt6::OpenGL)
endif()

# Create UI library
add_library(lumi_ui
    ui/LumiGUI.cpp
)

target_include_directories(lumi_ui PUBLIC
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(lumi_ui PUBLIC lumi_interop)

# Main executable - Lumi286
add_executable(Lumi286
    app/Lumi286.cpp
)

target_include_directories(Lumi286 PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(Lumi286 PRIVATE
    lumi_base
    lumi_cores
    lumi_orchestrator
    lumi_llm
    lumi_interop
    lumi_ui
)

# Link vcpkg packages
if(yaml-cpp_FOUND)
    target_link_libraries(Lumi286 PRIVATE yaml-cpp)
endif()

if(nlohmann_json_FOUND)
    target_link_libraries(Lumi286 PRIVATE nlohmann_json::nlohmann_json)
endif()

if(Qt6_FOUND)
    target_link_libraries(Lumi286 PRIVATE Qt6::Widgets Qt6::OpenGL)
endif()

# Link PhysX if found
if(PhysX5_FOUND)
    target_link_libraries(Lumi286 PRIVATE PhysX::PhysX)
endif()

# Link TensorRT if found
if(TensorRT_FOUND)
    target_link_libraries(Lumi286 PRIVATE TensorRT::nvinfer)
    if(TARGET TensorRT::nvinfer_plugin)
        target_link_libraries(Lumi286 PRIVATE TensorRT::nvinfer_plugin)
    endif()
endif()

# Optional: Alternative main executable using src/main/main.cpp
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/main/main.cpp")
    add_executable(lumi_app
        main/main.cpp
    )

    target_include_directories(lumi_app PRIVATE
        ${CMAKE_SOURCE_DIR}/include
    )

    target_link_libraries(lumi_app PRIVATE
        lumi_base
        lumi_cores
    )

    if(yaml-cpp_FOUND)
        target_link_libraries(lumi_app PRIVATE yaml-cpp)
    endif()

    if(nlohmann_json_FOUND)
        target_link_libraries(lumi_app PRIVATE nlohmann_json::nlohmann_json)
    endif()

    if(GTest_FOUND)
        target_link_libraries(lumi_app PRIVATE GTest::gtest)
    endif()
endif()
