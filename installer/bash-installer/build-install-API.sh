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
sudo cp ./systemd/powerjoular_api.py /usr/local/bin
sudo chmod +x /usr/local/bin/powerjoular_api.py

# Install systemd service
cat ./systemd/powerjoular22407.service | sed "s~_USER_~${USER}~g" > /tmp/powerjoular.service
sudo cp /tmp/powerjoular.service /etc/systemd/system/powerjoular.service


echo "Run
sudo systemctl enable powerjoular
sudo systemctl start powerjoular"
