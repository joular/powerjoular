#!/bin/sh

# Remove binaries from /usr/bin
# Requires sudo or root access
sudo rm /usr/bin/powerjoular

# Remove /etc/powerjoular folder and all its content
sudo rm -rf /etc/powerjoular/

# Remove systemd service
sudo rm /etc/systemd/system/powerjoular.service
