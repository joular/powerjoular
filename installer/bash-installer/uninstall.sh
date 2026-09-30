#!/bin/sh

# Stop and disable the service if it was enabled
if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl disable --now powerjoular.service 2>/dev/null
fi

# Remove the binary and the systemd service
# Requires sudo or root access
sudo rm -f /usr/bin/powerjoular
sudo rm -f /usr/lib/systemd/system/powerjoular.service

if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl daemon-reload
fi
