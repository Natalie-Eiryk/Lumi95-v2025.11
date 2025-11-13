# =============================================================================
# Verifies Visual Studio C++ toolchain for MSVC builds. Tries vswhere.
# =============================================================================
if(NOT WIN32)
  return()
endif()

include_guard(GLOBAL)
include("${CMAKE_SOURCE_DIR}/cmake/Safeguards--Core.cmake")

function(lumi_sg_ensure_vs)
  # Try vswhere (bundled with VS installers; often on PATH under Program Files)
  set(_pf_x86 "ProgramFiles(x86)")
find_program(VSWHERE_EXE NAMES vswhere
  HINTS
  "$ENV{ProgramFiles}/Microsoft Visual Studio/Installer"
  "$ENV{${_pf_x86}}/Microsoft Visual Studio/Installer")
  if(NOT VSWHERE_EXE)
    lumi_sg_warn("vswhere not found. If using Visual Studio Generator, ensure VS 2022 with Desktop C++ workload is installed.")
    return()
  endif()

  execute_process(
    COMMAND "${VSWHERE_EXE}" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    OUTPUT_VARIABLE _vs
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(_vs)
    lumi_sg_log("VS found at: ${_vs}")
  else()
    if(LUMI_AUTO_INSTALL)
      lumi_sg_warn("Cannot auto-install VS. Please install VS 2022 + Desktop C++ workload.")
    else()
      lumi_sg_warn("VS C++ toolchain missing. Install Visual Studio 2022 with Desktop C++ workload.")
    endif()
  endif()
endfunction()
