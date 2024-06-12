#!/bin/bash

# Function to check user permissions to write to the current directory
if [ ! -w "$(pwd)" ]; then
    echo "ERROR: You don't have write permission on the directory $(pwd)."
    exit 1
fi

# List of architectures to cross-compile for
ARCHS=("x86_64" "aarch64" "armv7h")

# Source directory for PKGBUILD
PKG_DIR="arch_pkgbuild"
OUTPUT_DIR="arch_source_packages"
rm -rf $PKG_DIR $OUTPUT_DIR
mkdir -p $PKG_DIR $OUTPUT_DIR

# Copy the PKGBUILD file to the build directory
cp PKGBUILD $PKG_DIR/

# Change directory to PKGBUILD
cd $PKG_DIR

# Loop through each architecture and cross-compile
for ARCH in "${ARCHS[@]}"; do
    # Set up the environment for cross-compiling
    case $ARCH in
        "x86_64")
            CROSS_COMPILE=""
            ;;
        "aarch64")
            CROSS_COMPILE="aarch64-linux-gnu-"
            ;;
        "armv7h")
            CROSS_COMPILE="arm-linux-gnueabihf-"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Export the necessary environment variables
    export CC="${CROSS_COMPILE}gcc"
    export CXX="${CROSS_COMPILE}g++"
    export AR="${CROSS_COMPILE}ar"
    export RANLIB="${CROSS_COMPILE}ranlib"

    # Update PKGBUILD architecture
    sed -i "s/^arch=.*/arch=('$ARCH')/" PKGBUILD

     # Build the package
    makepkg -Acfs --noconfirm

    # Move the generated package to the output directory with architecture name
    mv *.pkg.tar.zst ../$OUTPUT_DIR/powerjoular-$ARCH.pkg.tar.zst

    # Clean up the build directory for the next architecture
    rm -rf src pkg
done

# Clean up temporary directories
cd ..
rm -rf $PKG_DIR

echo "Arch packages have been created and moved to the '$OUTPUT_DIR' directory."

