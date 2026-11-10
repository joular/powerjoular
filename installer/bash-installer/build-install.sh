#!/bin/sh
set -e

# Go to the top of the repository, wherever this script was called from
cd "$(dirname "$0")/../.."

# Alire fetches the Joular Core and CPU Load libraries on its own
if command -v alr > /dev/null 2>&1; then
    alr build
else
    # Without Alire, the two libraries are expected to be checked out next to this repository
    echo "Alire not found, building with gprbuild against ../joularcore and ../cpuload"
    gprbuild -P powerjoular.gpr -aP../joularcore -aP../cpuload -p
fi

# install replaces the file rather than writing into it, which Linux refuses while the program runs
sudo install -Dm755 ./bin/powerjoular /usr/bin/powerjoular

sudo install -Dm644 ./systemd/powerjoular.service /usr/lib/systemd/system/powerjoular.service

if command -v systemctl > /dev/null 2>&1; then
    sudo systemctl daemon-reload
fi

# PowerJoular 1.x put its unit in /etc, where systemd prefers it to the one just installed
if [ -e /etc/systemd/system/powerjoular.service ]; then
    echo "WARNING: /etc/systemd/system/powerjoular.service takes over the new unit." >&2
    echo "Unless you wrote it yourself, remove it, then run: sudo systemctl daemon-reload" >&2
fi
