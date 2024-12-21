#!/bin/sh

# Go back to main directory
cd ../..

# Create obj/ folder it not exist
mkdir -p obj

# First build the project with gprbuild
gprbuild powerjoular.gpr

# Installer binaries to /usr/bin
# Requires sudo or root access
sudo cp ./obj/powerjoular /usr/bin/

# Install systemd service
sudo cp ./systemd/powerjoular.service /etc/systemd/system/
