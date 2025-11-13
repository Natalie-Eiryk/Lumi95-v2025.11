# =============================================================================
# CUDA + Nsight detection + sensible defaults
# Exposes (CACHE):
#   LUMI_CUDA_FOUND            : BOOL
#   LUMI_CUDA_TOOLKIT_ROOT     : PATH
#   LUMI_CUDA_ARCHS            : STRING (semicolon list, e.g., "86;89")
#   LUMI_CUDNN_HINT            : PATH (optional)
#   LUMI_Nsight_FOUND          : BOOL
# Functions:
#   lumi_sg_ensure_cuda([ARCHS "80;86;89"] [REQUIRED])
# Notes:
#   - Does not auto-install CUDA; only detects and configures.
# =============================================================================
include_guard(GLOBAL)

function(_cuda_log m)  
message(STATUS   "[Lumi][CUDA] ${m}") 
endfunction()
function(_cuda_warn m) 
message(WARNING "[Lumi][CUDA] ${m}") 
endfunction()

function(lumi_sg_ensure_cuda)
  set(options REQUIRED)
  set(oneValueArgs)
  set(multiValueArgs ARCHS)
  cmake_parse_arguments(_ "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # choose default archs if not provided; Ampere+Lovelace common
  if(NOT _ARCHS)
    set(_ARCHS "86;89")
  endif()

  # Try CUDAToolkit via CMake
  find_package(CUDAToolkit QUIET)
  if(CUDAToolkit_FOUND)
    set(LUMI_CUDA_FOUND ON CACHE BOOL "" FORCE)
    set(LUMI_CUDA_TOOLKIT_ROOT "${CUDAToolkit_ROOT}" CACHE PATH "" FORCE)
    set(LUMI_CUDA_ARCHS "${_ARCHS}" CACHE STRING "" FORCE)
    _cuda_log("CUDAToolkit found at '${CUDAToolkit_ROOT}', archs='${LUMI_CUDA_ARCHS}'")
  else()
    # Manual hints common on Windows
    if(WIN32 AND EXISTS "$ENV{CUDA_PATH}")
      set(LUMI_CUDA_TOOLKIT_ROOT "$ENV{CUDA_PATH}" CACHE PATH "" FORCE)
      set(LUMI_CUDA_FOUND ON CACHE BOOL "" FORCE)
      set(LUMI_CUDA_ARCHS "${_ARCHS}" CACHE STRING "" FORCE)
      _cuda_log("Using CUDA_PATH='${LUMI_CUDA_TOOLKIT_ROOT}', archs='${LUMI_CUDA_ARCHS}'")
    else()
      set(LUMI_CUDA_FOUND OFF CACHE BOOL "" FORCE)
      if(_.REQUIRED)
        message(FATAL_ERROR "[Lumi][CUDA] CUDA toolkit not found but REQUIRED was set.")
      else()
        _cuda_warn("CUDA toolkit not found; GPU features will be disabled.")
      endif()
    endif()
  endif()

  # cublas/cudnn hinting (optional)
  if(DEFINED ENV{CUDNN_ROOT} AND EXISTS "$ENV{CUDNN_ROOT}")
    set(LUMI_CUDNN_HINT "$ENV{CUDNN_ROOT}" CACHE PATH "cuDNN root hint" FORCE)
    _cuda_log("cuDNN hint: '${LUMI_CUDNN_HINT}'")
  endif()

  # Nsight detection (best-effort)
  set(LUMI_Nsight_FOUND OFF CACHE BOOL "" FORCE)
  if(WIN32)
    if(EXISTS "$ENV{ProgramFiles}/NVIDIA Corporation/Nsight Systems/nsys.exe")
      set(LUMI_Nsight_FOUND ON CACHE BOOL "" FORCE)
      _cuda_log("Nsight Systems found.")
    endif()
  else()
    find_program(_nsys nsys)
    if(_nsys)
      set(LUMI_Nsight_FOUND ON CACHE BOOL "" FORCE)
      _cuda_log("Nsight Systems found: ${_nsys}")
    endif()
  endif()
endfunction()
