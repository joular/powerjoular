#!/bin/bash

# List of architectures
ARCHITECTURES=("amd64" "arm64" "armhf")

# Directory of precompiled binaries
BIN_DIR="../obj"

# Systemd service file directory
SERVICE_DIR="../systemd"

# Output directory for packages
OUTPUT_DIR="deb_binary_packages"
rm -rf $OUTPUT_DIR

mkdir -p $OUTPUT_DIR

# For each architecture
for ARCH in "${ARCHITECTURES[@]}"
do
    # Create a new directory structure for architecture
    rm -rf $ARCH
    mkdir -p $ARCH/powerjoular/usr/bin
    mkdir -p $ARCH/powerjoular/etc/systemd/system
    mkdir -p $ARCH/powerjoular/DEBIAN

    # Copy precompiled binaries to bin directory
    cp $BIN_DIR/powerjoular $ARCH/powerjoular/usr/bin/

    # Copy systemd service files
    cp $SERVICE_DIR/powerjoular.service $ARCH/powerjoular/etc/systemd/system/

    # Copy the corresponding control files
    cp ./debian-control-$ARCH.txt $ARCH/powerjoular/DEBIAN/control

    # Go to the architecture directory
    cd $ARCH

    # Extract version from control file
    VERSION=$(grep '^Version:' powerjoular/DEBIAN/control | awk '{print $2}')

    # Creating a .deb package
    dpkg-deb --build powerjoular
    mv powerjoular.deb ../${OUTPUT_DIR}/powerjoular_${VERSION}_${ARCH}.deb

    # Return to previous directory
    cd ..
    
    # Delete temporary files from the architecture
    rm -rf $ARCH
done

echo "All .deb binary packages have been created and moved to the '${OUTPUT_DIR}' director>

