@echo off
REM Father & Son - local animation maker (ROG Ally X / any Windows PC).
REM Installs Python packages into a local venv. Run once, then run_queue.bat.
cd /d %~dp0
where python >nul 2>nul || (echo Install Python 3.11 from python.org first, tick "Add to PATH". & pause & exit /b 1)
python -m venv venv
call venv\Scripts\activate
python -m pip install --upgrade pip
REM AMD Radeon 890M (ROG Ally X) is gfx1150: try the ROCm-on-Windows PyTorch
REM nightlies for gfx1150, then gfx1151 (Strix Halo), else DirectML.
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1150/ torch torchvision 2>nul || (
  pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ torch torchvision 2>nul || (
    echo ROCm build not available - using DirectML instead.
    pip install torch-directml
  )
)
pip install diffusers transformers accelerate sentencepiece ftfy imageio imageio-ffmpeg pillow
echo.
echo Done. Now run run_queue.bat (leave it overnight).
pause
