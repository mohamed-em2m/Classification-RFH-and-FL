@echo off
REM ###############################################################################
REM # Setup Script for RFH-FL Classification Project (Windows)
REM # Automates environment creation and dependency installation
REM # Supports both CPU and GPU configurations
REM ###############################################################################

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_NAME=rfh-fl-classification
set PYTHON_VERSION=3.12
set VENV_NAME=rfh-fl-env
set VENV_PATH=.venv
set INSTALL_TYPE=
set COMMAND_ARG=%1

REM Color codes (using limited colors for Windows compatibility)
set "SUCCESS=[SUCCESS]"
set "ERROR=[ERROR]"
set "WARNING=[WARNING]"
set "INFO=[INFO]"

REM Parse command-line arguments
if /i "!COMMAND_ARG!"=="--cuda" (
    set INSTALL_TYPE=1
    echo.
    echo %INFO% GPU (CUDA 12.8) mode selected via argument
    echo.
) else if /i "!COMMAND_ARG!"=="--cpu" (
    set INSTALL_TYPE=2
    echo.
    echo %INFO% CPU-only mode selected via argument
    echo.
) else if /i "!COMMAND_ARG!"=="--help" (
    echo Usage: setup.bat [OPTIONS]
    echo.
    echo Options:
    echo   --cuda    Install with CUDA 12.8 support (GPU)
    echo   --cpu     Install CPU-only version
    echo   --help    Show this help message
    echo.
    echo Examples:
    echo   setup.bat --cuda    # Setup with GPU support
    echo   setup.bat --cpu     # Setup CPU-only version
    echo   setup.bat           # Interactive mode (prompts for choice)
    echo.
    pause
    exit /b 0
) else if not "!COMMAND_ARG!"=="" (
    echo %ERROR% Unknown argument: !COMMAND_ARG!
    echo.
    echo Usage: setup.bat [OPTIONS]
    echo Options: --cuda, --cpu, --help
    echo.
    pause
    exit /b 1
)

cls
echo.
echo ========================================
echo RFH-FL Classification Project Setup
echo ========================================
echo.
echo This script will set up the complete development environment
echo for the RFH-FL AI classification framework.
echo.

REM Step 1: Check Python
echo %INFO% Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo %ERROR% Python is not installed or not in PATH
    echo Please install Python 3.12 or higher from https://www.python.org/
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_INSTALLED=%%i
echo %SUCCESS% Python %PYTHON_INSTALLED% found
echo.

REM Step 2: Check CUDA
echo %INFO% Checking NVIDIA CUDA availability...
where nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('nvidia-smi --query-gpu=driver_version --format^=csv,noheader 2^>nul') do set DRIVER_VERSION=%%i
    echo %SUCCESS% NVIDIA GPU detected (Driver: !DRIVER_VERSION!)
    set HAS_CUDA=1
) else (
    echo %WARNING% NVIDIA GPU not detected.
    set HAS_CUDA=0
)
echo.

REM Step 3: Determine installation type
if not "!INSTALL_TYPE!"=="" (
    REM Argument was provided, INSTALL_TYPE already set
    echo.
) else (
    REM Interactive mode - ask user
    echo ========================================
    echo Installation Type Selection
    echo ========================================
    if !HAS_CUDA! equ 1 (
        echo GPU (CUDA 12.8) support is available on this system.
        echo.
        echo 1 = GPU (CUDA 12.8) - Recommended if NVIDIA GPU available
        echo 2 = CPU only
        echo.
        set /p INSTALL_TYPE="Select installation type (1 or 2): "
    ) else (
        echo %WARNING% GPU support not available. Installing CPU version.
        set INSTALL_TYPE=2
    )
)
echo.

REM Step 4: Check if venv already exists
if exist "%VENV_PATH%" (
    echo %WARNING% Virtual environment already exists at %VENV_PATH%
    set /p RECREATE="Remove and recreate? (y/n): "
    if /i "!RECREATE!"=="y" (
        echo %INFO% Removing old virtual environment...
        rmdir /s /q "%VENV_PATH%"
        if !errorlevel! equ 0 (
            echo %SUCCESS% Old virtual environment removed
        )
    ) else (
        echo %INFO% Using existing virtual environment
        goto activate_venv
    )
)

REM Step 5: Create virtual environment
echo ========================================
echo Creating Virtual Environment
echo ========================================
python -m venv "%VENV_PATH%"
if %errorlevel% equ 0 (
    echo %SUCCESS% Virtual environment created at %VENV_PATH%
) else (
    echo %ERROR% Failed to create virtual environment
    pause
    exit /b 1
)
echo.

REM Step 6: Activate virtual environment
:activate_venv
echo %INFO% Activating virtual environment...
call "%VENV_PATH%\Scripts\activate.bat"
echo %SUCCESS% Virtual environment activated
echo.

REM Step 7: Upgrade pip
echo ========================================
echo Upgrading pip and build tools
echo ========================================
python -m pip install --upgrade pip setuptools wheel >nul 2>&1
if %errorlevel% equ 0 (
    echo %SUCCESS% pip, setuptools, and wheel upgraded
) else (
    echo %WARNING% Could not upgrade all tools, continuing anyway...
)
echo.

REM Step 8: Install dependencies
if %INSTALL_TYPE% equ 1 (
    echo ========================================
    echo Installing dependencies (GPU mode - CUDA 12.8)
    echo ========================================
    echo %INFO% Installing PyTorch GPU (CUDA 12.8)...
    pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128
    if !errorlevel! equ 0 (
        echo %SUCCESS% PyTorch GPU installed
    ) else (
        echo %ERROR% Failed to install PyTorch GPU
    )
) else (
    echo ========================================
    echo Installing dependencies (CPU mode)
    echo ========================================
    echo %INFO% Installing PyTorch CPU...
    pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu
    if !errorlevel! equ 0 (
        echo %SUCCESS% PyTorch CPU installed
    ) else (
        echo %ERROR% Failed to install PyTorch CPU
    )
)
echo.

echo %INFO% Installing project dependencies...
pip install -e ".[dev]"
if %errorlevel% equ 0 (
    echo %SUCCESS% Project dependencies installed
) else (
    echo %WARNING% Some dependencies may not have installed correctly
)
echo.

REM Step 9: Verify installation
echo ========================================
echo Verifying Installation
echo ========================================
python -c "import torch; print('PyTorch version:', torch.__version__)" 2>nul
if %errorlevel% equ 0 (
    echo %SUCCESS% PyTorch verified
) else (
    echo %ERROR% PyTorch verification failed
)

python -c "import numpy; print('NumPy version:', numpy.__version__)" 2>nul
if %errorlevel% equ 0 (
    echo %SUCCESS% NumPy verified
) else (
    echo %ERROR% NumPy verification failed
)

python -c "import pandas; print('Pandas version:', pandas.__version__)" 2>nul
if %errorlevel% equ 0 (
    echo %SUCCESS% Pandas verified
) else (
    echo %ERROR% Pandas verification failed
)

python -c "import sklearn; print('Scikit-learn version:', sklearn.__version__)" 2>nul
if %errorlevel% equ 0 (
    echo %SUCCESS% Scikit-learn verified
) else (
    echo %ERROR% Scikit-learn verification failed
)

if %INSTALL_TYPE% equ 1 (
    python -c "import torch; print('GPU Available:', torch.cuda.is_available())"
)
echo.

REM Step 10: Print final instructions
echo ========================================
echo Setup Complete!
echo ========================================
echo %SUCCESS% Environment setup completed successfully!
echo.
echo Next Steps:
echo 1. Activate the environment:
echo    %VENV_PATH%\Scripts\activate.bat
echo.
echo 2. Verify the setup:
echo    python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
echo.
echo 3. Run inference:
echo    python inferance.py --input_dir ./data/test/ --output_dir ./results/
echo.
if %INSTALL_TYPE% equ 1 (
    echo 4. Check GPU acceleration:
    echo    python -c "import torch; print(f'GPU available: {torch.cuda.is_available()}')"
    echo.
)
echo Documentation:
echo   - README.md - Project overview and usage
echo   - MODEL_CARD.txt - Model details and specifications
echo   - models/ - Model implementations
echo.

pause
