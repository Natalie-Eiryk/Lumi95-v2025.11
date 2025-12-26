# Safeguards--EnsureOllama.cmake
# Auto-detect and install Ollama for LLM integration

function(lumi_sg_ensure_ollama)
    if(NOT LUMI_AUTO_INSTALL)
        return()
    endif()

    lumi_sg_info("Checking for Ollama...")

    # Check if Ollama is already installed
    find_program(OLLAMA_EXECUTABLE ollama)

    if(OLLAMA_EXECUTABLE)
        lumi_sg_good("Ollama found: ${OLLAMA_EXECUTABLE}")
        set(LUMI_OLLAMA_AVAILABLE TRUE PARENT_SCOPE)

        # Check if Ollama service is running
        execute_process(
            COMMAND ${OLLAMA_EXECUTABLE} list
            RESULT_VARIABLE OLLAMA_RUNNING
            OUTPUT_QUIET
            ERROR_QUIET
        )

        if(OLLAMA_RUNNING EQUAL 0)
            lumi_sg_good("Ollama service is running")
        else()
            lumi_sg_warn("Ollama installed but service not running")
            lumi_sg_info("Will attempt to start during build")
        endif()

        return()
    endif()

    # Ollama not found - attempt installation
    lumi_sg_warn("Ollama not found - attempting auto-install")

    if(WIN32)
        # Windows: Download and run installer
        lumi_sg_info("Downloading Ollama for Windows...")

        set(OLLAMA_INSTALLER "${CMAKE_BINARY_DIR}/OllamaSetup.exe")
        set(OLLAMA_URL "https://ollama.com/download/OllamaSetup.exe")

        file(DOWNLOAD
            "${OLLAMA_URL}"
            "${OLLAMA_INSTALLER}"
            SHOW_PROGRESS
            STATUS DOWNLOAD_STATUS
        )

        list(GET DOWNLOAD_STATUS 0 DOWNLOAD_RESULT)
        if(NOT DOWNLOAD_RESULT EQUAL 0)
            lumi_sg_warn("Failed to download Ollama installer")
            lumi_sg_warn("Please install manually from: https://ollama.com/download")
            set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
            return()
        endif()

        lumi_sg_info("Running Ollama installer (silent mode)...")
        execute_process(
            COMMAND "${OLLAMA_INSTALLER}" /S
            RESULT_VARIABLE INSTALL_RESULT
        )

        if(INSTALL_RESULT EQUAL 0)
            lumi_sg_good("Ollama installed successfully!")

            # Wait for installation to complete
            execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 3)

            # Find newly installed Ollama
            find_program(OLLAMA_EXECUTABLE ollama)

            if(OLLAMA_EXECUTABLE)
                lumi_sg_good("Ollama executable found: ${OLLAMA_EXECUTABLE}")
                set(LUMI_OLLAMA_AVAILABLE TRUE PARENT_SCOPE)
            else()
                lumi_sg_warn("Ollama installed but executable not found in PATH")
                lumi_sg_warn("May need to restart shell or add to PATH manually")
                set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
            endif()
        else()
            lumi_sg_warn("Ollama installation failed")
            set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
        endif()

        # Clean up installer
        file(REMOVE "${OLLAMA_INSTALLER}")

    elseif(APPLE)
        # macOS: Use Homebrew
        find_program(BREW_EXECUTABLE brew)

        if(BREW_EXECUTABLE)
            lumi_sg_info("Installing Ollama via Homebrew...")
            execute_process(
                COMMAND ${BREW_EXECUTABLE} install ollama
                RESULT_VARIABLE INSTALL_RESULT
            )

            if(INSTALL_RESULT EQUAL 0)
                lumi_sg_good("Ollama installed via Homebrew")
                set(LUMI_OLLAMA_AVAILABLE TRUE PARENT_SCOPE)
            else()
                lumi_sg_warn("Homebrew installation failed")
                set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
            endif()
        else()
            lumi_sg_warn("Homebrew not found - cannot auto-install Ollama")
            lumi_sg_warn("Install manually: https://ollama.com/download")
            set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
        endif()

    else()
        # Linux: Use install script
        lumi_sg_info("Installing Ollama via official script...")
        execute_process(
            COMMAND sh -c "curl -fsSL https://ollama.com/install.sh | sh"
            RESULT_VARIABLE INSTALL_RESULT
        )

        if(INSTALL_RESULT EQUAL 0)
            lumi_sg_good("Ollama installed via install script")
            set(LUMI_OLLAMA_AVAILABLE TRUE PARENT_SCOPE)
        else()
            lumi_sg_warn("Install script failed")
            set(LUMI_OLLAMA_AVAILABLE FALSE PARENT_SCOPE)
        endif()
    endif()

endfunction()

# Function to ensure a model is pulled
function(lumi_sg_ensure_ollama_model MODEL_NAME)
    if(NOT LUMI_OLLAMA_AVAILABLE)
        return()
    endif()

    find_program(OLLAMA_EXECUTABLE ollama)
    if(NOT OLLAMA_EXECUTABLE)
        return()
    endif()

    lumi_sg_info("Checking for Ollama model: ${MODEL_NAME}")

    # Check if model already exists
    execute_process(
        COMMAND ${OLLAMA_EXECUTABLE} list
        OUTPUT_VARIABLE OLLAMA_MODELS
        ERROR_QUIET
    )

    string(FIND "${OLLAMA_MODELS}" "${MODEL_NAME}" MODEL_FOUND)

    if(MODEL_FOUND GREATER -1)
        lumi_sg_good("Model ${MODEL_NAME} already available")
    else()
        lumi_sg_info("Pulling model ${MODEL_NAME} (this may take a few minutes)...")

        execute_process(
            COMMAND ${OLLAMA_EXECUTABLE} pull ${MODEL_NAME}
            RESULT_VARIABLE PULL_RESULT
            OUTPUT_VARIABLE PULL_OUTPUT
            ERROR_VARIABLE PULL_ERROR
        )

        if(PULL_RESULT EQUAL 0)
            lumi_sg_good("Model ${MODEL_NAME} pulled successfully")
        else()
            lumi_sg_warn("Failed to pull model ${MODEL_NAME}")
            lumi_sg_warn("You can pull it manually: ollama pull ${MODEL_NAME}")
        endif()
    endif()
endfunction()

# Function to start Ollama service if not running
function(lumi_sg_start_ollama)
    if(NOT LUMI_OLLAMA_AVAILABLE)
        return()
    endif()

    find_program(OLLAMA_EXECUTABLE ollama)
    if(NOT OLLAMA_EXECUTABLE)
        return()
    endif()

    lumi_sg_info("Ensuring Ollama service is running...")

    # Check if already running
    execute_process(
        COMMAND ${OLLAMA_EXECUTABLE} list
        RESULT_VARIABLE SERVICE_RUNNING
        OUTPUT_QUIET
        ERROR_QUIET
    )

    if(SERVICE_RUNNING EQUAL 0)
        lumi_sg_good("Ollama service already running")
    else()
        lumi_sg_info("Starting Ollama service...")

        if(WIN32)
            # Windows: Start as background process
            execute_process(
                COMMAND cmd /c start /B ${OLLAMA_EXECUTABLE} serve
                OUTPUT_QUIET
                ERROR_QUIET
            )
        else()
            # Unix: Start in background
            execute_process(
                COMMAND sh -c "${OLLAMA_EXECUTABLE} serve &"
                OUTPUT_QUIET
                ERROR_QUIET
            )
        endif()

        # Wait for service to start
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 2)

        lumi_sg_good("Ollama service started")
    endif()
endfunction()
