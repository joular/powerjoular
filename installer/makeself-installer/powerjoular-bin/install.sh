#!/bin/sh

# Requires sudo or root access

echo "Installing PowerJoular binary"

# Installer binaries to /usr/bin
sudo cp ./powerjoular /usr/bin/
sudo cp ./powerjoular-uninstall.sh /usr/bin/
sudo chmod a+rx /usr/bin/powerjoular /usr/bin/powerjoular-uninstall.sh

echo "Installing PowerJoular systemd service"

# Install systemd service
sudo cp ./powerjoular.service /etc/systemd/system/
sudo chmod a+rx /etc/systemd/system/powerjoular.service

echo "Installation complete!"
