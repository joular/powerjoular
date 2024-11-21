#!/bin/sh
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
ME="${0##*/}"

# Go back to main directory
cd $MY_PATH/../..

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
sudo cp -f ./systemd/powerjoular.service /etc/systemd/system/

cat ./systemd/powerjoular22407.service | sed "s~_USER_~${USER}~g" > /tmp/powerjoularAPI.service
sudo cp /tmp/powerjoularAPI.service /etc/systemd/system/


echo "Run
sudo systemctl daemon-reload

sudo systemctl enable powerjoular
sudo systemctl enable powerjoularAPI
sudo systemctl start powerjoular
sudo systemctl start powerjoularAPI"
