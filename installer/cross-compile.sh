#!/bin/bash

# Cross-Compilation Script for Powerjoular
set -e  # Exit on any error

# Define architecture specific settings
declare -A archs=(
  ["x86_64"]="x86_64-linux-gnu"
  ["armv7"]="arm-linux-gnueabihf"
  ["aarch64"]="aarch64-linux-gnu"
)

# Clean previous builds
rm -rf build/
mkdir -p build

# Loop through each architecture
for arch in "${!archs[@]}"; do
  target=${archs[$arch]}
  
  echo "Building for architecture: $arch, using target: $target..."
  mkdir -p "build/$arch"

  # Compile using gprbuild for the specific target
  gprbuild -P../powerjoular.gpr --target=$target --RTS=$target -XTARGET=$target -XBUILD_MODE=release -XLIBRARY_TYPE=relocatable -o "build/$arch/powerjoular"

  echo "Compilation completed for $arch"

  # Here you can add any post-compilation steps, like packaging or additional logging
done

echo "All builds and packaging completed."
