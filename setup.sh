#!/bin/bash

###############################################################################
# Setup Script for RFH-FL Classification Project
# Uses uv for fast, reliable environment and dependency management
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
VENV_PATH=".venv"
PYTHON_VERSION="3.12"
INSTALL_TYPE=""

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

install_uv() {
    print_header "Checking uv"

    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version | awk '{print $2}')
        print_success "uv $UV_VERSION already installed"
        return
    fi

    print_info "uv not found — installing..."
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget &> /dev/null; then
        wget -qO - https://astral.sh/uv/install.sh | sh
    else
        print_error "Neither curl nor wget found. Please install uv manually: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi

    # Reload PATH so uv is available in this session
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &> /dev/null; then
        print_error "uv installation failed. Please install it manually: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi

    print_success "uv $(uv --version | awk '{print $2}') installed"
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

    print_info "Creating virtual environment with Python $PYTHON_VERSION..."
    uv venv "$VENV_PATH" --python "$PYTHON_VERSION"
    print_success "Virtual environment created at $VENV_PATH"
}

activate_venv() {
    print_info "Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
    print_success "Virtual environment activated"
}

###############################################################################
# Dependency Installation
###############################################################################

install_dependencies() {
    if [ "$INSTALL_TYPE" = "gpu" ]; then
        print_header "Installing dependencies (GPU mode — CUDA 12.8)"

        # Install PyTorch GPU from the PyTorch CUDA index
        uv pip install \
            torch==2.8.0 \
            torchvision==0.23.0 \
            torchaudio==2.8.0 \
            --index-url https://download.pytorch.org/whl/cu128
        print_success "PyTorch GPU (CUDA 12.8) installed"
    else
        print_header "Installing dependencies (CPU mode)"

        # Install PyTorch CPU from the PyTorch CPU index
        uv pip install \
            torch==2.8.0 \
            torchvision==0.23.0 \
            torchaudio==2.8.0 \
            --index-url https://download.pytorch.org/whl/cpu
        print_success "PyTorch CPU installed"
    fi

    # Install the project and all remaining dependencies (including [dev] extras)
    uv pip install -e ".[dev]"
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
    echo -e "${BLUE}Run commands with uv (no manual activation needed):${NC}"
    echo -e "   ${YELLOW}uv run python inferance.py --input_dir ./data/test/ --output_dir ./results/${NC}"
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

    install_uv
    echo ""

    check_cuda
    echo ""

    create_venv
    echo ""

    activate_venv
    echo ""

    install_dependencies
    echo ""

    verify_installation
    echo ""

    print_final_instructions
}

main "$@"