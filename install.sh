#!/bin/bash

# INFORMATION READ BEFORE EXEC PLEASE !
# We use Wine 64-bit to run the Windows version of Python and PyInstaller
# from Linux. This allows PyInstaller to build Windows executables
# using the Windows Python environment on Linux.
#
# WINEARCH=win64 forces the Wine prefix to use a 64-bit Windows environment.
# wine32 is intentionally NOT installed because this project targets
# 64-bit Windows executables only. No need wine32 anymore !

set -e

echo "[INFO] Detecting Linux distribution..."
DISTRO=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
echo "[INFO] Distribution detected: $DISTRO"

# ---------- INSTALL WINE ----------
echo "[INFO] Installing Wine and dependencies (wine32 included)..."
sudo dpkg --add-architecture i386
sudo apt-get update -y
sudo apt-get install -y \
    wine64 \
    wget \
    curl \
    unzip \
    cabextract \
    fuseiso

# ---------- CREATE WINEPREFIX ----------
# Create a clean 64-bit Wine prefix in the user's HOME directory instead of root wich is not secure !
export WINEARCH=win64
export WINEPREFIX="$HOME/.wine"

# Check $WINEPREFIX in case you exec again
echo "[INFO] Creating clean 64-bit Wine prefix..."
if [ -d "$WINEPREFIX" ]; then
    echo "[INFO] Removing existing Wine prefix..."
    rm -rf "$WINEPREFIX"
fi

mkdir -p "$WINEPREFIX"  # Ensuring directory exist !

# Then Init
wineboot --init
echo "[INFO] Setting Windows version to Win11..."
#winetricks -q win11
#winetricks -q vcrun2022

# ---------- INSTALL PYTHON EMBED ----------
echo "[INFO] Downloading Python 3.13.7 embeddable..."
cd /tmp
wget -O py-embed.zip https://www.python.org/ftp/python/3.13.7/python-3.13.7-embed-amd64.zip
mkdir -p "$WINEPREFIX/drive_c/py313"
unzip py-embed.zip -d "$WINEPREFIX/drive_c/py313"

# Enable import site
sed -i 's/#import site/import site/' "$WINEPREFIX/drive_c/py313/python313._pth"

# ---------- INSTALL PIP ----------
echo "[INFO] Installing pip..."
wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
wine "$WINEPREFIX/drive_c/py313/python.exe" get-pip.py

echo "[INFO] Installing pip dependencies..."
wine "$WINEPREFIX/drive_c/py313/python.exe" -m pip install --upgrade pip setuptools wheel

# ---------- INSTALL PYINSTALLER, PYWIN32, KEYBOARD ----------
echo "[INFO] Installing PyInstaller, PyWin32 and Keyboard..."
wine "$WINEPREFIX/drive_c/py313/python.exe" -m pip install pyinstaller
wine "$WINEPREFIX/drive_c/py313/python.exe" -m pip install pywin32
wine "$WINEPREFIX/drive_c/py313/python.exe" -m pip install keyboard # replacement for pyHook

# -- END -- 
echo "[INFO] Setup completed successfully!"
