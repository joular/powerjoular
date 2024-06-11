#!/bin/bash

# Fonction pour vérifier les permissions de l'utilisateur pour écrire dans le répertoire courant
if [ ! -w "$(pwd)" ]; then
    echo "ERREUR : Vous n'avez pas la permission en écriture sur le répertoire $(pwd)."
    exit 1
fi

# Répertoire source pour le PKGBUILD
PKG_DIR="arch_pkgbuild"
OUTPUT_DIR="arch_source_packages"
rm -rf $PKG_DIR $OUTPUT_DIR
mkdir -p $PKG_DIR $OUTPUT_DIR

# Copier le fichier PKGBUILD dans le répertoire de construction
cp PKGBUILD $PKG_DIR/

# Changer de répertoire pour PKGBUILD
cd $PKG_DIR

# Construire le package
makepkg

# Déplacer le package généré dans le répertoire de sortie
mv *.pkg.tar.zst ../$OUTPUT_DIR/

# Nettoyer les répertoires temporaires
cd ..
rm -rf $PKG_DIR

echo "Arch package has been created and moved to the '$OUTPUT_DIR' directory."
