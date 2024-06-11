#!/bin/bash



# Fonction pour vérifier les permissions de l'utilisateur pour écrire dans le répertoire courant
if [ ! -w $(pwd) ]; then
    echo "ERREUR : Vous n'avez pas la permission en écriture sur le répertoire $(pwd)."
    exit 1
fi

# Répertoire source pour le PKGBUILD
PKG_DIR="arch_pkgbuild"
OUTPUT_DIR="arch_source_packages"
rm -rf $PKG_DIR $OUTPUT_DIR
mkdir -p $PKG_DIR $OUTPUT_DIR

# Créer le fichier PKGBUILD
cat <<EOL > $PKG_DIR/PKGBUILD
# Maintainer: Adel Noureddine <adel.noureddine@univ-pau.fr>
# Contributor: Axel TERRIER <axelterrier12071999@gmail.com>
pkgname=powerjoular
pkgver=0.7.3
pkgrel=1
pkgdesc="PowerJoular allows monitoring power consumption of multiple platforms and processes."
arch=('x86_64' 'aarch64' 'armv7h')
url="https://github.com/axelterrier/powerjoular"
license=('GPL3')
depends=('gcc-ada' 'gprbuild' 'xmlada' 'libgpr')
source=("$pkgname-\$pkgver.tar.gz::https://github.com/axelterrier/powerjoular/archive/refs/heads/develop.tar.gz")
sha256sums=('SKIP')

build() {
    cd "\$srcdir/\$pkgname-develop"
    gprbuild -P powerjoular.gpr
}

package() {
    cd "\$srcdir/\$pkgname-develop"
    install -Dm755 obj/powerjoular "\$pkgdir/usr/bin/powerjoular"
    install -Dm644 systemd/powerjoular.service "\$pkgdir/usr/lib/systemd/system/powerjoular.service"
}
EOL

echo "PKGBUILD created in $PKG_DIR."

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
