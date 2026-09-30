#!/bin/bash

# Stop at the first error, so a failed makepkg does not carry on
set -euo pipefail

if [ ! -w "$(pwd)" ]; then
    echo "ERROR: You don't have write permission on the directory $(pwd)."
    exit 1
fi

PKG_DIR="arch_pkgbuild"
OUTPUT_DIR="arch_source_packages"
rm -rf $PKG_DIR $OUTPUT_DIR
mkdir -p $PKG_DIR $OUTPUT_DIR

cp PKGBUILD $PKG_DIR/

cd $PKG_DIR

makepkg

mv *.pkg.tar.zst ../$OUTPUT_DIR/

cd ..
rm -rf $PKG_DIR

echo "Arch package has been created and moved to the '$OUTPUT_DIR' directory."
