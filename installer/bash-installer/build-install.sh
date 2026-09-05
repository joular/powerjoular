#!/bin/sh
set -e

# Go to the top of the repository, wherever this script was called from
cd "$(dirname "$0")/../.."

# Build the program
# Alire fetches the Joular Core and CPU Load libraries on its own
if command -v alr > /dev/null 2>&1; then
    alr build
else
    # Without Alire, the two libraries are expected to be checked out next to this repository
    echo "Alire not found, building with gprbuild against ../joularcore and ../cpuload"
    gprbuild -P powerjoular.gpr -aP../joularcore -aP../cpuload -p
fi

# Install the binary in /usr/bin
# Requires sudo or root access
sudo cp ./bin/powerjoular /usr/bin/

# Install the systemd service
sudo cp ./systemd/powerjoular.service /etc/systemd/system/
