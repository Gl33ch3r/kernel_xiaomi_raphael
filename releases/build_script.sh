#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

# Configuration Variables
KERNEL_REPO="https://github.com/Evolution-X-Devices/kernel_xiaomi_raphael.git"
BRANCH="cnb"
DEFCONFIG="vendor/sm8150_defconfig"
ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/out"
THREAD_COUNT="$(nproc --all)"

echo "=================================================="
echo " Starting Evolution X Kernel Compilation for Raphael"
echo " Branch: $BRANCH | Defconfig: $DEFCONFIG"
echo " Cores: $THREAD_COUNT"
echo "=================================================="

# 1. Clone repository if it doesn't exist, otherwise pull latest changes
if [ ! -d "kernel_xiaomi_raphael" ]; then
    echo "[-] Cloning kernel repository..."
    git clone --depth=1 -b "$BRANCH" "$KERNEL_REPO"
else
    echo "[-] Repository already exists. Pulling latest changes..."
    cd kernel_xiaomi_raphael
    git pull origin "$BRANCH"
    cd "$ROOT_DIR"
fi

cd kernel_xiaomi_raphael

# 2. Setup Architecture Environment Variables
export ARCH=arm64
export SUBARCH=arm64

# 3. Prepare output directory and clean previous builds
mkdir -p "$OUT_DIR"

echo "[-] Cleaning previous build artifacts..."
make O="$OUT_DIR" ARCH=arm64 mrproper

# Verify defconfig exists
if [ ! -f "arch/arm64/configs/$DEFCONFIG" ]; then
    echo "[-] Config arch/arm64/configs/$DEFCONFIG not found."
    echo "[-] Available vendor configs:"
    ls -la arch/arm64/configs/vendor/
    exit 1
fi

echo "[-] Generating configuration ($DEFCONFIG)..."
make O="$OUT_DIR" ARCH=arm64 "$DEFCONFIG"

echo "[-] Compiling kernel..."
make O="$OUT_DIR" \
    ARCH=arm64 \
    CC=clang \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LD=ld.lld \
    -j"$THREAD_COUNT"

echo "=================================================="
if [ -f "$OUT_DIR/arch/arm64/boot/Image.gz" ] || [ -f "$OUT_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "[+] Kernel compilation successful!"
    echo "[+] Output Directory: $OUT_DIR/arch/arm64/boot/"
else
    echo "[-] Compilation finished, but output image was not found."
    exit 1
fi
echo "=================================================="