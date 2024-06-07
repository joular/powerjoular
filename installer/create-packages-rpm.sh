#!/bin/sh

# Define architectures
ARCHS=("x86_64" "aarch64" "armhfp")

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Loop over each architecture
for ARCH in "${ARCHS[@]}"
do
    rm -rf $SCRIPT_DIR/$ARCH
    
    # Create folder for architecture
    mkdir -p $SCRIPT_DIR/$ARCH

    # Copy binary and service files to their respective directories
    cp $SCRIPT_DIR/../obj/powerjoular $SCRIPT_DIR/$ARCH/
    cp $SCRIPT_DIR/../systemd/powerjoular.service $SCRIPT_DIR/$ARCH/

    # Prepare the RPM build environment
    mkdir -p $SCRIPT_DIR/$ARCH/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    cp $SCRIPT_DIR/powerjoular.spec $SCRIPT_DIR/$ARCH/rpmbuild/SPECS/

    # Copy the sources accordingly
    cp $SCRIPT_DIR/$ARCH/powerjoular $SCRIPT_DIR/$ARCH/rpmbuild/SOURCES/
    cp $SCRIPT_DIR/$ARCH/powerjoular.service $SCRIPT_DIR/$ARCH/rpmbuild/SOURCES/

    # Build the RPM package
    cd $SCRIPT_DIR/$ARCH
    rpmbuild -ba rpmbuild/SPECS/powerjoular.spec --define "_topdir $(pwd)/rpmbuild" --target $ARCH

    # Move the created RPM to a more accessible location
    find rpmbuild/RPMS/ -name '*.rpm' -exec mv {} $SCRIPT_DIR/$ARCH/ \;
done

# Combine all RPM packages into a single directory for convenience
mkdir -p $SCRIPT_DIR/all_rpms
for ARCH in "${ARCHS[@]}"
do
    mv $SCRIPT_DIR/$ARCH/*.rpm $SCRIPT_DIR/all_rpms/
done

echo "All RPM packages have been created and moved to the 'all_rpms' directory in $SCRIPT_DIR."
