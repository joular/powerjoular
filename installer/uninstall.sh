#!/bin/sh

# Remove binaries from /usr/bin
# Requires sudo or root access
sudo rm /usr/bin/powerjoular

# Remove systemd service
sudo rm /etc/systemd/system/powerjoular.service
