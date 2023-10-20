#!/bin/sh

# Create folder structure
mkdir -p powerjoular/usr/bin powerjoular/etc/systemd/system powerjoular/DEBIAN

# Copy binary files for deb package
cp ../../obj/powerjoular ./powerjoular/usr/bin/
cp ../../systemd/powerjoular.service ./powerjoular/etc/systemd/system/

# Create deb package
dpkg-deb --build powerjoular
