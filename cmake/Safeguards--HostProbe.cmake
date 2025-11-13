# =============================================================================
# HostProbe: collect hardware/OS facts that influence builds
# -----------------------------------------------------------------------------
# Exposes (CACHE):
#   LUMI_HOST_OS                 : STRING   (Windows|Linux|Darwin|...)
#   LUMI_HOST_ARCH               : STRING   (x86_64|arm64|...)
#   LUMI_HOST_IS_64BIT           : BOOL
#   LUMI_HOST_CPU_MODEL          : STRING
#   LUMI_HOST_CPU_PHYSICAL_CORES : STRING (int)
#   LUMI_HOST_CPU_LOGICAL_CORES  : STRING (int)
#   LUMI_HOST_RAM_MB             : STRING (int)
#   LUMI_HOST_RAM_GB             : STRING (int)
#   LUMI_HOST_GPU_VENDOR         : STRING (NVIDIA|AMD|Intel|Apple|Unknown)
#   LUMI_HOST_GPU_NAMES          : STRING (semicolon list)
#   LUMI_HOST_CUDA_CAPABLE       : BOOL
#   LUMI_HOST_NOTES              : STRING (warnings/hints)
#
# Functions:
#   lumi_probe_host()  # populates and logs the above once per configure
#
# Requires: CMake ?3.18 for cmake_host_system_information queries (earlier works
#           for many fields but this path is tested on 3.22+).
# =============================================================================
include_guard(GLOBAL)

function(_hp_log m)  
message(STATUS   "[Lumi][HOST] ${m}") 
endfunction()
function(_hp_warn m) 
message(WARNING "[Lumi][HOST] ${m}") 
endfunction()

function(_hp_set_cache name value type)
  set(${name} "${value}" CACHE ${type} "" FORCE)
endfunction()

# --- helpers ---------------------------------------------------------------
function(_hp_trim IN OUT)
  string(REGEX REPLACE "^[ \t\r\n]+|[ \t\r\n]+$" "" _t "${IN}")
  set(${OUT} "${_t}" PARENT_SCOPE)
endfunction()

# Try platform-native ways to extract a line of text
function(_hp_get_cpu_model OUT)
  if(WIN32)
    # Prefer CIM; fall back to wmic if necessary
    execute_process(
      COMMAND powershell -NoProfile -ExecutionPolicy Bypass
              "($x=Get-CimInstance Win32_Processor | Select-Object -First 1 -Expand Name) -join ''"
      OUTPUT_VARIABLE _name OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE _rc)
    if(NOT _rc EQUAL 0 OR _name STREQUAL "")
      execute_process(COMMAND wmic cpu get Name
        OUTPUT_VARIABLE _raw OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REPLACE "\r" "" _raw "${_raw}")
      string(REPLACE "\n" ";" _lines "${_raw}")
      list(LENGTH _lines _n)
      if(_n GREATER 1)
        list(GET _lines 1 _name)
      endif()
    endif()
  elseif(APPLE)
    execute_process(COMMAND /usr/sbin/sysctl -n machdep.cpu.brand_string
      OUTPUT_VARIABLE _name OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    if(EXISTS "/proc/cpuinfo")
      execute_process(COMMAND bash -lc "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2-"
        OUTPUT_VARIABLE _name OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()
    if("${_name}" STREQUAL "")
      find_program(_lscpu lscpu)
      if(_lscpu)
        execute_process(COMMAND "${_lscpu}" OUTPUT_VARIABLE _out)
        string(REGEX MATCH "Model name:[ \t]*(.+)\n" _m "${_out}")
        set(_name "${CMAKE_MATCH_1}")
      endif()
    endif()
  endif()
  _hp_trim("${_name}" _name)
  set(${OUT} "${_name}" PARENT_SCOPE)
endfunction()

function(_hp_get_gpus OUT_NAMES OUT_VENDOR OUT_CUDA)
  set(_names "")
  set(_vendor "Unknown")
  set(_cuda OFF)

  # 1) NVIDIA (nvidia-smi)
  find_program(_nvsmi nvidia-smi)
  if(_nvsmi)
    # query names as CSV no header
    execute_process(COMMAND "${_nvsmi}" --query-gpu=name --format=csv,noheader
      OUTPUT_VARIABLE _csv OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _rc)
    if(_rc EQUAL 0 AND NOT _csv STREQUAL "")
      string(REPLACE "\r" "" _csv "${_csv}")
      string(REPLACE "\n" ";" _names "${_csv}")
      set(_vendor "NVIDIA")
      set(_cuda ON)
    endif()
  endif()

  # 2) Windows generic via CIM
  if(_names STREQUAL "" AND WIN32)
    execute_process(
      COMMAND powershell -NoProfile -ExecutionPolicy Bypass
              "Get-CimInstance Win32_VideoController | Select-Object -Expand Name"
      OUTPUT_VARIABLE _out OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE _rc)
    if(_rc EQUAL 0 AND NOT _out STREQUAL "")
      string(REPLACE "\r" "" _out "${_out}")
      string(REPLACE "\n" ";" _lines "${_out}")
      set(_names "${_lines}")
      string(TOLOWER "${_out}" _lower)
      if(_lower MATCHES "nvidia")      
      set(_vendor "NVIDIA")
      elseif(_lower MATCHES "advanced micro|amd")  
      set(_vendor "AMD")
      elseif(_lower MATCHES "intel")    
      set(_vendor "Intel")
      endif()
      if(_vendor STREQUAL "NVIDIA")     
      set(_cuda ON) 
      endif()
    endif()
  endif()

  # 3) macOS
  if(_names STREQUAL "" AND APPLE)
    execute_process(COMMAND /usr/sbin/system_profiler SPDisplaysDataType
      OUTPUT_VARIABLE _out OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCHALL "Chipset Model: ([^\n]+)" _all "${_out}")
    foreach(_line ${_all})
      string(REGEX REPLACE "Chipset Model: " "" _n "${_line}")
      list(APPEND _names "${_n}")
    endforeach()
    if(NOT _names STREQUAL "")
      set(_vendor "Apple") # may also be AMD, but Apple Silicon is common
    endif()
  endif()

  # 4) Linux (lspci)
  if(_names STREQUAL "" AND UNIX AND NOT APPLE)
    find_program(_lspci lspci)
    if(_lspci)
      execute_process(COMMAND "${_lspci}" -nnk
        OUTPUT_VARIABLE _out OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REGEX MATCHALL "VGA compatible controller: ([^\n]+)" _all "${_out}")
      foreach(_line ${_all})
        string(REGEX REPLACE "VGA compatible controller: " "" _n "${_line}")
        list(APPEND _names "${_n}")
      endforeach()
      if(NOT _names STREQUAL "")
        string(TOLOWER "${_out}" _lower)
        if(_lower MATCHES "nvidia") 
        set(_vendor "NVIDIA")
        elseif(_lower MATCHES "amd|advanced micro") 
        set(_vendor "AMD")
        elseif(_lower MATCHES "intel") 
        set(_vendor "Intel")
        endif()
        if(_vendor STREQUAL "NVIDIA") 
        set(_cuda ON) 
        endif()
      endif()
    endif()
  endif()

  if(_names STREQUAL "")
    set(_names "Unknown GPU")
  endif()
  list(JOIN _names ";" _names_joined)
  set(${OUT_NAMES} "${_names_joined}" PARENT_SCOPE)
  set(${OUT_VENDOR} "${_vendor}" PARENT_SCOPE)
  set(${OUT_CUDA} "${_cuda}" PARENT_SCOPE)
endfunction()

# --- main -------------------------------------------------------------------
function(lumi_probe_host)
  # OS & arch
  _hp_set_cache(LUMI_HOST_OS   "${CMAKE_HOST_SYSTEM_NAME}" STRING)
  _hp_set_cache(LUMI_HOST_ARCH "${CMAKE_HOST_SYSTEM_PROCESSOR}" STRING)

  # core counts, RAM, 64-bit flags via CMake
  include(${CMAKE_ROOT}/Modules/CMakeHostSystemInformation.cmake OPTIONAL)
  cmake_host_system_information(RESULT _is64   QUERY IS_64BIT)
  cmake_host_system_information(RESULT _lc     QUERY NUMBER_OF_LOGICAL_CORES)
  cmake_host_system_information(RESULT _pc     QUERY NUMBER_OF_PHYSICAL_CORES)
  cmake_host_system_information(RESULT _ram_kb QUERY TOTAL_PHYSICAL_MEMORY)

  if(NOT _lc) 
  set(_lc "${CMAKE_HOST_SYSTEM_PROCESSOR_COUNT}") 
  endif()

  math(EXPR _ram_mb "${_ram_kb} / 1024"       OUTPUT_FORMAT DECIMAL)
  math(EXPR _ram_gb "${_ram_kb} / 1048576"    OUTPUT_FORMAT DECIMAL)

  _hp_set_cache(LUMI_HOST_IS_64BIT           "${_is64}"  BOOL)
  _hp_set_cache(LUMI_HOST_CPU_PHYSICAL_CORES "${_pc}"    STRING)
  _hp_set_cache(LUMI_HOST_CPU_LOGICAL_CORES  "${_lc}"    STRING)
  _hp_set_cache(LUMI_HOST_RAM_MB             "${_ram_mb}" STRING)
  _hp_set_cache(LUMI_HOST_RAM_GB             "${_ram_gb}" STRING)

  # CPU model string (best effort)
  _hp_get_cpu_model(_cpu_model)
  if(_cpu_model STREQUAL "")  # fallback
    set(_cpu_model "${LUMI_HOST_ARCH}")
  endif()
  _hp_set_cache(LUMI_HOST_CPU_MODEL "${_cpu_model}" STRING)

  # GPUs
  _hp_get_gpus(_gpu_names _gpu_vendor _cuda)
  _hp_set_cache(LUMI_HOST_GPU_NAMES    "${_gpu_names}" STRING)
  _hp_set_cache(LUMI_HOST_GPU_VENDOR   "${_gpu_vendor}" STRING)
  _hp_set_cache(LUMI_HOST_CUDA_CAPABLE "${_cuda}" BOOL)

  # Heuristic notes (thresholds you can tune)
  set(_notes "")
  if(LUMI_HOST_RAM_GB AND LUMI_HOST_RAM_GB LESS 16)
    list(APPEND _notes "Low RAM (<16GB): consider reducing parallel builds or disabling heavy features.")
  endif()
  if(LUMI_HOST_GPU_VENDOR STREQUAL "NVIDIA" AND NOT LUMI_HOST_CUDA_CAPABLE)
    list(APPEND _notes "NVIDIA detected but nvidia-smi absent; CUDA runtime may be missing.")
  endif()
  list(JOIN _notes " | " _notes_joined)
  _hp_set_cache(LUMI_HOST_NOTES "${_notes_joined}" STRING)

  # Log a concise line:
  _hp_log("OS=${LUMI_HOST_OS}  Arch=${LUMI_HOST_ARCH}  64bit=${LUMI_HOST_IS_64BIT}")
  _hp_log("CPU='${LUMI_HOST_CPU_MODEL}'  Cores P/L=${LUMI_HOST_CPU_PHYSICAL_CORES}/${LUMI_HOST_CPU_LOGICAL_CORES}")
  _hp_log("RAM=${LUMI_HOST_RAM_GB} GB (${LUMI_HOST_RAM_MB} MB)")
  _hp_log("GPU Vendor=${LUMI_HOST_GPU_VENDOR}  CUDA=${LUMI_HOST_CUDA_CAPABLE}  Names=${LUMI_HOST_GPU_NAMES}")
  if(NOT "${LUMI_HOST_NOTES}" STREQUAL "")
    _hp_warn("${LUMI_HOST_NOTES}")
  endif()
endfunction()
