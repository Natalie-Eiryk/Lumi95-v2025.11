# =============================================================================
# Network preflight: detects online/offline, proxy hints, and basic reachability
# Exposes:
#   LUMI_NET_ONLINE            : BOOL
#   LUMI_NET_PROXY_IN_EFFECT   : BOOL
#   lumi_net_check()           : populates the above and logs details
# =============================================================================
include_guard(GLOBAL)

function(lumi_net_log msg)  
message(STATUS   "[Lumi][NET] ${msg}") 
endfunction()
function(lumi_net_warn msg) 
message(WARNING "[Lumi][NET] ${msg}") 
endfunction()
# Allow explicit override
set(LUMI_NET_ASSUME_OFFLINE "${LUMI_NET_ASSUME_OFFLINE}" CACHE BOOL "Force offline behavior in preflight")
set(LUMI_NET_FORCE_ONLINE  "${LUMI_NET_FORCE_ONLINE}"  CACHE BOOL "Force online behavior (skip reachability checks)")
function(lumi_net_check)
if(LUMI_NET_FORCE_ONLINE AND LUMI_NET_ASSUME_OFFLINE)
    lumi_net_warn("Both LUMI_NET_FORCE_ONLINE and LUMI_NET_ASSUME_OFFLINE are set; honoring the force-online override.")
  endif()

  if(LUMI_NET_FORCE_ONLINE)
    set(LUMI_NET_ONLINE ON PARENT_SCOPE)
    set(LUMI_NET_ONLINE ON CACHE BOOL "[Lumi] Network reachable")
    set(LUMI_NET_PROXY_IN_EFFECT OFF PARENT_SCOPE)
    set(LUMI_NET_PROXY_IN_EFFECT OFF CACHE BOOL "[Lumi] Proxy detected")
    message(STATUS "[Lumi][NET] Force-online override active: skipping reachability checks.")
    return()
  endif()
  if(LUMI_NET_ASSUME_OFFLINE)
    set(LUMI_NET_ONLINE OFF PARENT_SCOPE)
    set(LUMI_NET_ONLINE OFF CACHE BOOL "[Lumi] Network reachable")
    set(LUMI_NET_PROXY_IN_EFFECT OFF PARENT_SCOPE)
    set(LUMI_NET_PROXY_IN_EFFECT OFF CACHE BOOL "[Lumi] Proxy detected")
    message(STATUS "[Lumi][NET] Assume offline: skipping reachability checks.")
    return()
  endif()

  # proxies?
  set(_proxy_vars http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY no_proxy)
  set(LUMI_NET_PROXY_IN_EFFECT OFF PARENT_SCOPE)
  set(LUMI_NET_PROXY_IN_EFFECT OFF CACHE BOOL "[Lumi] Proxy detected")
  foreach(_p IN LISTS _proxy_vars)
    if(DEFINED ENV{${_p}} AND NOT "$ENV{${_p}}" STREQUAL "")
      lumi_net_log("Proxy detected: ${_p}=$ENV{${_p}}")
      set(LUMI_NET_PROXY_IN_EFFECT ON PARENT_SCOPE)
      set(LUMI_NET_PROXY_IN_EFFECT ON CACHE BOOL "[Lumi] Proxy detected")
    endif()
  endforeach()

  # quick reach tests (best-effort, cross-platform)
  if(WIN32)
    execute_process(COMMAND powershell -NoProfile -ExecutionPolicy Bypass
      -Command "try { (Invoke-WebRequest -Uri 'https://www.msftconnecttest.com/connecttest.txt' -UseBasicParsing -TimeoutSec 5).StatusCode } catch { 0 }"
      OUTPUT_VARIABLE _code OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    execute_process(COMMAND bash -lc "curl -I -sS --max-time 5 https://www.msftconnecttest.com/connecttest.txt | head -n1 | awk '{print $2}'"
      OUTPUT_VARIABLE _code OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
# Treat any HTTP response code other than the synthetic "000" as proof that we
  # can reach the network.  Some corporate proxies and hosted environments return
  # 30x/40x codes for msftconnecttest.com, which previously forced us into
  # offline mode even though outbound traffic works just fine for vcpkg.
  set(_lumi_net_online OFF)
  if(_code MATCHES "^[0-9]+$")
    if(NOT _code STREQUAL "000")
      set(_lumi_net_online ON)
    endif()
  endif()

  if(_lumi_net_online)
    set(LUMI_NET_ONLINE ON PARENT_SCOPE)
    set(LUMI_NET_ONLINE ON CACHE BOOL "[Lumi] Network reachable")
    if(_code MATCHES "^(200|204)$")
      lumi_net_log("Online (status ${_code}).")
    else()
      lumi_net_warn("Connectivity probe returned HTTP ${_code}; assuming online because a response was received.")
    endif()
  else()
    set(LUMI_NET_ONLINE OFF PARENT_SCOPE)
    set(LUMI_NET_ONLINE OFF CACHE BOOL "[Lumi] Network reachable")
    lumi_net_warn("Offline or blocked (status '${_code}'). Install/fetch steps will be skipped unless already cached.")
  endif()
endfunction()
