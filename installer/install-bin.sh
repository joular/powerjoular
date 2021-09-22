#!/bin/sh

# Go back to main directory
cd ..

# Installer binaries to /usr/bin
# Requires sudo or root access
sudo cp ./packages/x86_64/powerjoular /usr/bin/

# Install systemd service
sudo cp ./systemd/powerjoular.service /etc/systemd/system/ 
