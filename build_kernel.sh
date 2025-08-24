#!/bin/bash

# =============================================================================
#           Self-Contained Exynos Kernel Build Script by Minhmc2007
#
# This script automatically handles its dependencies:
# 1. Checks for the required compiler toolchain.
# 2. Downloads the toolchain if it's missing.
# 3. Ensures the toolchain directory is ignored by Git.
# 4. Configures and builds the kernel.
# =============================================================================

# Stop the script immediately if any command fails
set -e

# --- Environment Setup ---

# Define the toolchain directory
TC_DIR="$(pwd)/toolchain"
GITIGNORE_FILE=".gitignore"

# Check if the toolchain directory exists
if [ ! -d "$TC_DIR" ]; then
    echo "Toolchain not found. Cloning AOSP Clang toolchain..."
    # Clone the complete toolchain. --depth=1 saves significant time and space.
    git clone https://github.com/AOSP-Clang/aosp-clang.git --depth=1 "$TC_DIR"
    echo "✅ Toolchain downloaded successfully."
fi

# Check if .gitignore exists and contains the toolchain entry
if [ ! -f "$GITIGNORE_FILE" ] || ! grep -q "toolchain/" "$GITIGNORE_FILE"; then
    echo "Adding 'toolchain/' to .gitignore..."
    # Create .gitignore if it doesn't exist and append the entry
    echo -e "\n# Ignore the downloaded compiler toolchain\ntoolchain/" >> "$GITIGNORE_FILE"
    echo "✅ .gitignore updated."
fi

# --- Compilation Variables ---

# Set kernel architecture
export ARCH=arm64
# Set cross-compiler prefixes for both 64-bit and 32-bit targets
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"
# Add the toolchain's 'bin' directory to the system's PATH
export PATH="${TC_DIR}/bin:${PATH}"

# --- Kernel Make Arguments ---
# These flags are passed to every 'make' command.
# - PLATFORM_VERSION & ANDROID_MAJOR_VERSION: Required by Android-specific kernel code.
# - LLVM=1: Instructs the build system to use the Clang/LLVM compiler.
# - LLVM_IAS=1: Tells Clang to use its powerful integrated assembler.
MAKE_ARGS="PLATFORM_VERSION=12 ANDROID_MAJOR_VERSION=s LLVM=1 LLVM_IAS=1"

# --- Build Process ---

# 1. Configure the kernel.
#    This command reads the specified defconfig file, which contains all the
#    baseline kernel options for the target device, and creates the final .config
#    file that the build system will use for compilation.
echo "⚙️  Configuring kernel with 's5e8825-a25xdxx_minhmc2007_config'..."
make ${MAKE_ARGS} s5e8825-a25xdxx_minhmc2007_config
echo "✅ Kernel configured successfully."

# 2. Build the kernel image.
#    -j$(nproc) uses all available CPU cores on your machine to build faster.
echo "🚀 Starting kernel build with $(nproc) cores..."
make ${MAKE_ARGS} -j$(nproc)

# --- Completion ---
echo ""
echo "🎉 Kernel build complete! 🎉"
echo "Your new kernel image can be found at: arch/arm64/boot/Image"
echo ""

# --- End of Script ---
