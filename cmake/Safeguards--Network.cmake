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
function(lumi_net_check)
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
  if(_code MATCHES "^(200|204)$")
    set(LUMI_NET_ONLINE ON PARENT_SCOPE)
    set(LUMI_NET_ONLINE ON CACHE BOOL "[Lumi] Network reachable")
    lumi_net_log("Online (status ${_code}).")
  else()
    set(LUMI_NET_ONLINE OFF PARENT_SCOPE)
     set(LUMI_NET_ONLINE OFF CACHE BOOL "[Lumi] Network reachable")
    lumi_net_warn("Offline or blocked (status '${_code}'). Install/fetch steps will be skipped unless already cached.")
  endif()
endfunction()
