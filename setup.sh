#!/bin/bash

###############################################################################
# Setup Script for RFH-FL Classification Project
# Automates environment creation and dependency installation
# Supports both CPU and GPU configurations
#
# Usage:
#   ./setup.sh --cuda    # Install with CUDA 12.8 support (GPU)
#   ./setup.sh --cpu     # Install CPU-only version
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="rfh-fl-classification"
PYTHON_VERSION="3.12"
VENV_NAME="rfh-fl-env"
VENV_PATH=".venv"
INSTALL_TYPE=""
NEEDS_PIP_INSTALL=false

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --cuda    Install with CUDA 12.8 support (GPU)"
    echo "  --cpu     Install CPU-only version"
    echo "  --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --cuda    # Setup with GPU support"
    echo "  $0 --cpu     # Setup CPU-only version"
}

###############################################################################
# Parse Arguments (required — no interactive fallback)
###############################################################################

parse_args() {
    if [ $# -eq 0 ]; then
        print_error "No argument provided. You must specify --cuda or --cpu."
        echo ""
        print_usage
        exit 1
    fi

    case "$1" in
        --cuda)
            INSTALL_TYPE="gpu"
            print_info "GPU (CUDA 12.8) mode selected"
            ;;
        --cpu)
            INSTALL_TYPE="cpu"
            print_info "CPU-only mode selected"
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $1"
            echo ""
            print_usage
            exit 1
            ;;
    esac
}

###############################################################################
# Check System Requirements
###############################################################################

check_python() {
    print_info "Checking Python installation..."

    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3.12 or higher."
        exit 1
    fi

    PYTHON_VERSION_INSTALLED=$(python3 --version | awk '{print $2}')
    print_success "Python $PYTHON_VERSION_INSTALLED found"

    if [[ ! $PYTHON_VERSION_INSTALLED == 3.12* ]]; then
        print_warning "Python 3.12.x is recommended. You have $PYTHON_VERSION_INSTALLED — continuing anyway."
    fi
}

check_cuda() {
    if [ "$INSTALL_TYPE" = "gpu" ]; then
        print_info "Checking CUDA availability..."
        if command -v nvidia-smi &> /dev/null; then
            CUDA_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
            print_success "NVIDIA GPU detected (Driver: $CUDA_DRIVER)"
        else
            print_warning "NVIDIA GPU not detected, but --cuda was requested. Proceeding anyway."
        fi
    fi
}

###############################################################################
# Environment Setup
###############################################################################

create_venv() {
    print_header "Creating Virtual Environment"

    if [ -d "$VENV_PATH" ]; then
        print_warning "Virtual environment already exists at $VENV_PATH — removing and recreating..."
        rm -rf "$VENV_PATH"
    fi

    print_info "Creating virtual environment..."
    if ! python3 -m venv "$VENV_PATH" 2>&1; then
        print_warning "Standard venv creation failed, trying without pip bootstrap..."
        python3 -m venv --without-pip "$VENV_PATH" || {
            print_error "Failed to create virtual environment"
            exit 1
        }
        NEEDS_PIP_INSTALL=true
    fi

    print_success "Virtual environment created at $VENV_PATH"
}

activate_venv() {
    print_info "Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
    print_success "Virtual environment activated"
}

upgrade_pip() {
    print_header "Upgrading pip and build tools"

    if [ "$NEEDS_PIP_INSTALL" = true ]; then
        print_info "Installing pip manually..."
        if command -v curl &> /dev/null; then
            curl -s https://bootstrap.pypa.io/get-pip.py | python3
        elif command -v wget &> /dev/null; then
            wget -qO - https://bootstrap.pypa.io/get-pip.py | python3
        else
            print_warning "Could not download get-pip.py. Trying ensurepip as fallback..."
            python3 -m ensurepip --upgrade --default-pip || print_warning "ensurepip also failed"
        fi
    fi

    python3 -m pip install --upgrade pip setuptools wheel 2>/dev/null || \
        print_warning "Could not upgrade pip/setuptools/wheel. Continuing with existing versions..."

    print_success "pip and build tools ready"
}

###############################################################################
# Dependency Installation
###############################################################################

install_dependencies() {
    if [ "$INSTALL_TYPE" = "gpu" ]; then
        print_header "Installing dependencies (GPU mode — CUDA 12.8)"
        pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 \
            --index-url https://download.pytorch.org/whl/cu128
        print_success "PyTorch GPU (CUDA 12.8) installed"
    else
        print_header "Installing dependencies (CPU mode)"
        pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 \
            --index-url https://download.pytorch.org/whl/cpu
        print_success "PyTorch CPU installed"
    fi

    pip install -e ".[dev]"
    print_success "Project dependencies installed"
}

###############################################################################
# Verification
###############################################################################

verify_installation() {
    print_header "Verifying Installation"

    python3 << 'EOF'
import sys
import importlib

packages = {
    "torch": "PyTorch",
    "torchvision": "TorchVision",
    "numpy": "NumPy",
    "pandas": "Pandas",
    "sklearn": "Scikit-learn",
    "matplotlib": "Matplotlib",
    "seaborn": "Seaborn",
    "PIL": "Pillow",
    "tqdm": "tqdm",
    "openpyxl": "OpenPyXL",
    "xgboost": "XGBoost",
    "shap": "SHAP",
}

print("\nInstalled Packages:")
print("-" * 40)

all_ok = True
for module_name, display_name in packages.items():
    try:
        module = importlib.import_module(module_name)
        version = getattr(module, "__version__", "unknown")
        print(f"✓ {display_name:<20} {version}")
    except ImportError:
        print(f"✗ {display_name:<20} NOT INSTALLED")
        all_ok = False

if all_ok:
    print("\n✓ All dependencies verified!")
    sys.exit(0)
else:
    print("\n✗ Some dependencies are missing!")
    sys.exit(1)
EOF

    if [ $? -eq 0 ]; then
        print_success "All dependencies verified"
    else
        print_error "Some dependencies are missing"
        exit 1
    fi
}

###############################################################################
# Final Instructions
###############################################################################

print_final_instructions() {
    print_header "Setup Complete!"
    echo ""
    print_success "Environment setup completed successfully!"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Activate the environment:"
    echo -e "   ${YELLOW}source $VENV_PATH/bin/activate${NC}"
    echo ""
    echo "2. Verify the setup:"
    echo -e "   ${YELLOW}python -c 'import torch; print(f\"PyTorch version: {torch.__version__}\")'${NC}"
    echo ""
    echo "3. Run inference:"
    echo -e "   ${YELLOW}python inferance.py --input_dir ./data/test/ --output_dir ./results/${NC}"
    echo ""
    echo "4. For GPU acceleration:"
    echo -e "   ${YELLOW}python -c 'import torch; print(f\"GPU available: {torch.cuda.is_available()}\")'${NC}"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  - README.md        - Project overview and usage"
    echo "  - MODEL_CARD.txt   - Model details and specifications"
    echo "  - models/          - Model implementations"
    echo ""
}

###############################################################################
# Main
###############################################################################

main() {
    clear
    print_header "RFH-FL Classification Project Setup"
    echo ""
    echo "This script will set up the complete development environment"
    echo "for the RFH-FL AI classification framework."
    echo ""

    parse_args "$@"
    echo ""

    check_python
    echo ""

    check_cuda
    echo ""

    create_venv
    echo ""

    activate_venv
    echo ""

    upgrade_pip
    echo ""

    install_dependencies
    echo ""

    verify_installation
    echo ""

    print_final_instructions
}

main "$@"