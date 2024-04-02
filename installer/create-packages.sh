#!/bin/sh

# For Debian, Ubuntu (.deb package)

for ARCH in amd64 arm64 armhf
do
    rm -rf $ARCH
    
    # Create folder for architecture and package format
    mkdir -p $ARCH/powerjoular/usr/bin $ARCH/powerjoular/etc/systemd/system $ARCH/powerjoular/DEBIAN

    # Copy binary files for deb package
    cp ../obj/powerjoular ./$ARCH/powerjoular/usr/bin/
    cp ../systemd/powerjoular.service ./$ARCH/powerjoular/etc/systemd/system/
    cp ./debian-control-$ARCH.txt ./$ARCH/powerjoular/DEBIAN/control

    # Create deb package
    cd ./$ARCH
    VERSION=$(grep '^Version:' powerjoular/DEBIAN/control | awk '{print $2}')
    dpkg-deb --build powerjoular
    mv powerjoular.deb powerjoular_${VERSION}_${ARCH}.deb
    cd ..
done

# For Red Hat, Fedora (.rpm package)
rm -rf rpmbuild
mkdir rpmbuild
cd rpmbuild
mkdir BUILD RPMS SOURCES SPECS SRPMS
cd ..
cp ../obj/powerjoular ./rpmbuild/SOURCES/
cp ../systemd/powerjoular.service ./rpmbuild/SOURCES/
cp ./powerjoular.spec ./rpmbuild/SPECS/
rpmbuild -bb --define "_topdir $(pwd)/rpmbuild" ./rpmbuild/SPECS/powerjoular.spec