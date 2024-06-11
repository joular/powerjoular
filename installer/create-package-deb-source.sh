#!/bin/bash

# Chemin vers les sources du projet
SOURCE_DIR="../src"

# Chemin vers le fichier GPR
GPR_FILE="../powerjoular.gpr"

# Liste des architectures
ARCHITECTURES=("amd64" "arm64" "armhf")

# Créer un répertoire pour les paquets source
OUTPUT_DIR="deb_source_package"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Pour chaque architecture
for ARCH in "${ARCHITECTURES[@]}"
do
    # Créer une nouvelle structure de répertoire pour l'architecture
    rm -rf $ARCH
    mkdir -p $ARCH/powerjoular/usr/src/powerjoular
    mkdir -p $ARCH/powerjoular/DEBIAN
    mkdir -p $ARCH/powerjoular/etc/powerjoular
    mkdir -p $ARCH/powerjoular/etc/systemd/system
    mkdir -p $ARCH/powerjoular/usr/bin

    # Copier les fichiers sources dans le répertoire du package
    cp -r $SOURCE_DIR/* $ARCH/powerjoular/usr/src/powerjoular

    # Copier les fichiers de configuration
    cp ../alire.toml $ARCH/powerjoular/etc/powerjoular/

    # Copier les fichiers de contrôle correspondants
    cp ./debian-control-$ARCH.txt $ARCH/powerjoular/DEBIAN/control

    # Créer un répertoire temporaire pour la compilation
    TEMP_BUILD_DIR=$(mktemp -d)
    mkdir -p $TEMP_BUILD_DIR/src
    cp -r $SOURCE_DIR/* $TEMP_BUILD_DIR/src
    cp $GPR_FILE $TEMP_BUILD_DIR

    # Compilation du projet Ada
    cd $TEMP_BUILD_DIR
    gprbuild -P powerjoular.gpr
    if [ $? -ne 0 ]; then
        echo "La compilation a échoué pour l'architecture $ARCH"
        cd -
        rm -rf $TEMP_BUILD_DIR
        continue
    fi

    # Copier les binaires compilés dans le répertoire bin
    cp ./obj/powerjoular $OLDPWD/$ARCH/powerjoular/usr/bin/

    # Nettoyer le répertoire temporaire
    cd -
    rm -rf $TEMP_BUILD_DIR

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
