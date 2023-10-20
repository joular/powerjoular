#!/bin/sh

# Create folders for pacakge formats
mkdir deb

# Create folder structure for debian
mkdir -p deb/powerjoular/usr/bin deb/powerjoular/etc/systemd/system deb/powerjoular/DEBIAN

# Copy binary files for deb package
cp ../obj/powerjoular ./deb/powerjoular/usr/bin/
cp ../systemd/powerjoular.service ./deb/powerjoular/etc/systemd/system/
cp ./debian-control-$1.txt ./deb/powerjoular/DEBIAN/control

# Create deb package
cd deb
dpkg-deb --build powerjoular
cd ..
