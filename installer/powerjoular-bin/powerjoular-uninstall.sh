#!/bin/sh

# Requires sudo or root access

echo "Uninstalling PowerJoular binary"

# Uninstall binaries to /usr/bin
sudo rm /usr/bin/powerjoular

echo "Uninstalling PowerJoular systemd service"

# Uninstall systemd service
sudo rm /etc/systemd/system/powerjoular.service

echo "Removing uninstall script"

sudo rm /usr/bin/powerjoular-uninstall.sh

echo "Uninstallation complete!"
