#!/bin/bash

# Function to check user permissions to write to current directory
if [ ! -w "$(pwd)" ]; then
    echo "ERROR: You don't have write permission on the directory $(pwd)."
    exit 1
fi

# Source directory for PKGBUILD
PKG_DIR="arch_pkgbuild"
OUTPUT_DIR="arch_source_packages"
rm -rf $PKG_DIR $OUTPUT_DIR
mkdir -p $PKG_DIR $OUTPUT_DIR

# Copy the PKGBUILD file to the build directory
cp PKGBUILD $PKG_DIR/

# Changer de répertoire pour PKGBUILD
cd $PKG_DIR

# Change directory to PKGBUILD
makepkg

#  Move the generated package to the output directory
mv *.pkg.tar.zst ../$OUTPUT_DIR/

#  Clean up temporary directories
cd ..
rm -rf $PKG_DIR

echo "Arch package has been created and moved to the '$OUTPUT_DIR' directory."
