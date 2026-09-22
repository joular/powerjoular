#!/bin/sh

# Remove binaries from /usr/bin
# Requires sudo or root access
sudo rm -f /usr/bin/powerjoular

# Remove systemd service
sudo rm -f /usr/lib/systemd/system/powerjoular.service