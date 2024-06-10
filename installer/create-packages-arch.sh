#!/bin/bash

# Définir les architectures cibles
ARCHS=("x86_64" "aarch64" "armv7h")

# Définir le nom du projet et la version
PROJECT_NAME="powerjoular"
VERSION="0.7.3"

# Créer le répertoire all_packages s'il n'existe pas
mkdir -p all_packages

# Fonction pour créer un paquet pour une architecture donnée
create_package() {
  ARCH=$1
  BUILD_DIR="build_${ARCH}"
  
  # Créer les répertoires nécessaires
  mkdir -p "${BUILD_DIR}/src" "${BUILD_DIR}/pkg" "${BUILD_DIR}/systemd"
  
  # Copier les fichiers nécessaires
  cp ../obj/powerjoular "${BUILD_DIR}/${PROJECT_NAME}"
  cp ../systemd/powerjoular.service "${BUILD_DIR}/powerjoular.service"
  cp PKGBUILD "${BUILD_DIR}/PKGBUILD"
  
  # Modifier le PKGBUILD pour l'architecture courante
  sed -i "s/^arch=.*$/arch=('${ARCH}')/" "${BUILD_DIR}/PKGBUILD"
  sed -i "s/^pkgver=.*$/pkgver=${VERSION}/" "${BUILD_DIR}/PKGBUILD"
  
  # Générer le paquet
  cd "${BUILD_DIR}" || exit
  makepkg -f
  
  # Copier le paquet généré dans le répertoire all_packages
  if compgen -G "*.pkg.tar.zst" > /dev/null; then
    cp *.pkg.tar.zst ../all_packages/
  else
      echo "Aucun paquet généré pour ${ARCH}."
  fi
  
  # Nettoyer le répertoire de construction
  cd .. || exit
  rm -rf "${BUILD_DIR}"
}

# Boucle sur chaque architecture et créer les paquets
for ARCH in "${ARCHS[@]}"; do
  create_package "${ARCH}"
done

echo "Tous les paquets ont été créés et stockés dans all_packages."

