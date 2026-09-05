#!/bin/bash

# Stop at the first thing that goes wrong
# Without this, a cross build that fails carries on to the packaging steps, which then happily
# produce a package with no binary inside it
set -euo pipefail

VERSION=2.0.0

# First cross compiler

# Architectures
ARCHS=("x86_64-linux-gnu" "aarch64-linux-gnu")

for ARCH in "${ARCHS[@]}"
do
    # Fetch the Joular Core and CPU Load libraries, then build against them
    rm -rf obj bin
    alr build -- --target=$ARCH
    mkdir -p ./binary/$ARCH
    cp ./bin/powerjoular ./binary/$ARCH/
done

# Create packages folder
rm -rf packages
mkdir -p packages


# Create deb packages

# Create deb temporary folder 
mkdir -p deb-temp
cd deb-temp

DEBIAN_ARCHITECTURES=("amd64" "arm64")

for DEB_ARCH in "${DEBIAN_ARCHITECTURES[@]}"
do
    # Create a new directory structure for architecture
    rm -rf $DEB_ARCH
    mkdir -p $DEB_ARCH/powerjoular/usr/bin
    mkdir -p $DEB_ARCH/powerjoular/usr/lib/systemd/system
    mkdir -p $DEB_ARCH/powerjoular/DEBIAN/
    chmod 755 $DEB_ARCH

    # Copy precompiled binaries to bin directory
    if [[ $DEB_ARCH = "amd64" ]]
    then
        cp ../binary/x86_64-linux-gnu/powerjoular $DEB_ARCH/powerjoular/usr/bin
    elif [[ $DEB_ARCH = "arm64" ]]
    then
        cp ../binary/aarch64-linux-gnu/powerjoular $DEB_ARCH/powerjoular/usr/bin
    fi

    # Copy systemd service files
    cp ../systemd/powerjoular.service $DEB_ARCH/powerjoular/usr/lib/systemd/system/

    # Create the control
    cat << EOL > $DEB_ARCH/powerjoular/DEBIAN/control
Package: powerjoular
Version: $VERSION
Maintainer: Adel Noureddine <adel.noureddine@outlook.com>
Architecture: $DEB_ARCH
Section: utils
Priority: optional
Depends: libc6
Homepage: https://github.com/joular/powerjoular
Description: Monitor the power consumption of hardware components, processes and software.
 PowerJoular monitors, in real time, the power consumption of the CPU and the
 GPU of the machine, and of one process or one application running on it.
 It exports the power data to the terminal, to CSV files, and to a shared
 memory ring buffer.
EOL

    cd $DEB_ARCH

    # Creating a .deb package
    dpkg-deb --build powerjoular
    mv powerjoular.deb ../../packages/powerjoular_${VERSION}_${DEB_ARCH}.deb

    cd ..
done

# Remove temp folder
cd ..
rm -rf deb-temp


# Create rpm packages

# The names rpm itself uses: a package built for "arm64" is one no aarch64 machine will install
RPM_ARCHITECTURES=("x86_64" "aarch64")

# Create rpm temporary folder 
mkdir -p rpm-temp
cd rpm-temp

for RPM_ARCH in "${RPM_ARCHITECTURES[@]}"
do
    # Create a new directory structure for architecture
    rm -rf $RPM_ARCH
    mkdir -p $RPM_ARCH

    
    
    # Prepare the RPM build environment
    mkdir -p $RPM_ARCH/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    cp ../installer/powerjoular.spec $RPM_ARCH/rpmbuild/SPECS/

    # Copy the sources accordingly

    if [[ $RPM_ARCH = "x86_64" ]]
    then
        cp ../binary/x86_64-linux-gnu/powerjoular $RPM_ARCH/rpmbuild/SOURCES/
    elif [[ $RPM_ARCH = "aarch64" ]]
    then
        cp ../binary/aarch64-linux-gnu/powerjoular $RPM_ARCH/rpmbuild/SOURCES/
    fi

    cp ../systemd/powerjoular.service $RPM_ARCH/rpmbuild/SOURCES/

    # Build the RPM package
    cd $RPM_ARCH
    rpmbuild -ba rpmbuild/SPECS/powerjoular.spec --define "_topdir $(pwd)/rpmbuild" --target $RPM_ARCH

    # Move the created RPM to packages
    find rpmbuild/RPMS/ -name '*.rpm' -exec mv {} ../../packages/ \;
    cd ..
done

# Remove temp folder
cd ..
rm -rf rpm-temp