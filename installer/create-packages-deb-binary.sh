#!/bin/bash

# Liste des architectures
ARCHITECTURES=("amd64" "arm64" "armhf")

# Répertoire des binaires précompilés
BIN_DIR="../obj"

# Répertoire des fichiers de service systemd
SERVICE_DIR="../systemd"

# Répertoire de sortie pour les paquets
OUTPUT_DIR="deb_binary_packages"
rm -rf $OUTPUT_DIR

mkdir -p $OUTPUT_DIR

# Pour chaque architecture
for ARCH in "${ARCHITECTURES[@]}"
do
    # Créer une nouvelle structure de répertoire pour l'architecture
    rm -rf $ARCH
    mkdir -p $ARCH/powerjoular/usr/bin
    mkdir -p $ARCH/powerjoular/etc/systemd/system
    mkdir -p $ARCH/powerjoular/DEBIAN

    # Copier les binaires précompilés dans le répertoire bin
    cp $BIN_DIR/powerjoular $ARCH/powerjoular/usr/bin/

    # Copier les fichiers de service systemd
    cp $SERVICE_DIR/powerjoular.service $ARCH/powerjoular/etc/systemd/system/

    # Copier les fichiers de contrôle correspondants
    cp ./debian-control-$ARCH.txt $ARCH/powerjoular/DEBIAN/control

    # Aller dans le répertoire de l'architecture
    cd $ARCH

    # Extraire la version à partir du fichier de contrôle
    VERSION=$(grep '^Version:' powerjoular/DEBIAN/control | awk '{print $2}')

    # Création du package .deb
    dpkg-deb --build powerjoular
    mv powerjoular.deb ../${OUTPUT_DIR}/powerjoular_${VERSION}_${ARCH}.deb

    # Revenir au répertoire précédent
    cd ..
    
    # Supprimer les fichiers temporaires de l'architecture
    rm -rf $ARCH
done

echo "All .deb binary packages have been created and moved to the '${OUTPUT_DIR}' director>

