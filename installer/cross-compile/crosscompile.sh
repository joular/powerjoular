#!/bin/bash

# Go back to main directory
cd ../..

# Create obj/ folder it not exist
mkdir -p obj

# Architectures
ARCHS=("x86_64-linux-gnu" "aarch64-linux-gnu")

for ARCH in "${ARCHS[@]}"; do
    gprbuild powerjoular.gpr --target=$ARCH
    mkdir -p installer/cross-compile/$ARCH
    cp ./obj/powerjoular ./installer/cross-compile/$ARCH/
done