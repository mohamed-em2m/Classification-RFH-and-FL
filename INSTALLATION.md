# Installation Guide

This document provides step-by-step instructions for setting up the RFH-FL Classification project on your system.

## Quick Start (Automated)

### Windows Users
```bash
setup.bat
```

### Linux/macOS Users
```bash
chmod +x setup.sh
./setup.sh
```

The automated setup will:
- ✓ Check system requirements (Python 3.12)
- ✓ Detect CUDA/GPU availability
- ✓ Create a virtual environment
- ✓ Install all dependencies (PyTorch, scientific libraries, etc.)
- ✓ Verify the installation
- ✓ Provide next steps

---

## Manual Installation (Step-by-Step)

If you prefer manual installation or the automated scripts don't work for you, follow these steps:

### 1. Prerequisites
- **Python:** 3.12 or higher ([Download](https://www.python.org/downloads/))
- **pip:** Latest version (usually comes with Python)
- **NVIDIA drivers** (Optional, for GPU support): CUDA 12.8 compatible drivers
- **Git:** For cloning the repository

### 2. Clone the Repository
```bash
git clone https://github.com/lucas-lacerda-de-souza/Classification-RFH-and-FL.git
cd Classification-RFH-and-FL
```

### 3. Create Virtual Environment

**Windows:**
```bash
python -m venv .venv
.venv\Scripts\activate.bat
```

**Linux/macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 4. Upgrade pip
```bash
python -m pip install --upgrade pip setuptools wheel
```

### 5. Install PyTorch

**For GPU (CUDA 12.8):**
```bash
pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128
```

**For CPU only:**
```bash
pip install torch==2.8.0 torchvision==0.19.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cpu
```

### 6. Install Project Dependencies

Install with development tools:
```bash
pip install -e ".[dev]"
```

Or minimal installation:
```bash
pip install -e .
```

### 7. Verify Installation

```bash
python -c "import torch; print(f'PyTorch: {torch.__version__}')"
python -c "import pandas; print(f'Pandas: {pandas.__version__}')"
python -c "import torch; print(f'GPU Available: {torch.cuda.is_available()}')"
```

---

## Package Structure

The `pyproject.toml` defines the following extras:

### Core Dependencies
```
numpy==1.26.4
pandas==2.2.3
scikit-learn==1.5.2
matplotlib==3.9.2
seaborn==0.13.2
pillow==10.4.0
tqdm==4.66.5
openpyxl==3.1.5
xgboost>=2.0.0
shap>=0.45.0
```

### Optional Dependencies

**PyTorch (CPU):**
```bash
pip install -e ".[torch-cpu]"
```

**PyTorch (GPU):**
```bash
pip install -e ".[torch-cuda]"
```

**Development Tools:**
```bash
pip install -e ".[dev]"
```
Includes: pytest, pytest-cov, black, flake8, mypy, jupyter, ipython

**Documentation:**
```bash
pip install -e ".[docs]"
```
Includes: sphinx, sphinx-rtd-theme

---

## Troubleshooting

### Python Version Issues
```bash
# Check your Python version
python --version

# If not 3.12, specify the full path
/usr/bin/python3.12 -m venv .venv
```

### CUDA Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi

# Update drivers from: https://www.nvidia.com/Download/driverDetails.aspx
```

### Virtual Environment Not Activating

**Windows - Execution Policy Error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.venv\Scripts\Activate.ps1
```

**Linux/macOS - Permission Error:**
```bash
chmod +x .venv/bin/activate
source .venv/bin/activate
```

### PyTorch Not Installing

Try alternative PyTorch index:
```bash
# Official index
pip install torch==2.8.0 -f https://download.pytorch.org/whl/torch_stable.html
```

### Import Errors After Installation

Reinstall development mode:
```bash
pip install --force-reinstall -e .
```

---

## System Requirements

### Minimum (CPU-only)
- **CPU:** 8+ cores recommended
- **RAM:** 8 GB minimum (16 GB+ recommended)
- **Disk:** 10 GB for dependencies + data

### Recommended (GPU)
- **GPU:** NVIDIA with CUDA Compute Capability 7.0+
- **VRAM:** 8 GB minimum (24 GB+ recommended for large batches)
- **RAM:** 32 GB+
- **Disk:** 50+ GB for data and model weights

### Tested Configuration
- **CPU:** Intel Xeon W-2295 (18 cores)
- **RAM:** 125 GB
- **GPU:** 3× NVIDIA GeForce RTX 3090 (24 GB each)
- **CUDA:** 12.8 compatible
- **Python:** 3.12.11

---

## Next Steps

1. **Run Inference:**
   ```bash
   python inferance.py --input_dir ./data/test/ --output_dir ./results/
   ```

2. **View Results:**
   ```bash
   # Results are saved in ./results/ directory
   ls -la results/
   ```

3. **Using Jupyter:**
   ```bash
   jupyter notebook
   ```

4. **Run Tests (if available):**
   ```bash
   pytest tests/
   ```

---

## References

- **Project Repository:** https://github.com/lucas-lacerda-de-souza/Classification-RFH-and-FL
- **Model Weights:** https://doi.org/10.5281/zenodo.18190502
- **PyTorch Installation:** https://pytorch.org/get-started/locally/
- **CUDA Toolkit:** https://developer.nvidia.com/cuda-toolkit
- **Python 3.12:** https://www.python.org/downloads/release/python-3120/

---

## Support

For issues or questions:
1. Check the [README.md](README.md) for project overview
2. Review [MODEL_CARD.txt](MODEL_CARD.txt) for model specifications
3. Open an issue on [GitHub](https://github.com/lucas-lacerda-de-souza/Classification-RFH-and-FL/issues)

---

**Last Updated:** May 2026
