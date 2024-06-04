#!/bin/bash

# Verification de la presence de rpmbuild
if ! command -v rpmbuild &> /dev/null; then
    echo "rpmbuild could not be found. This script is intended to run on a system with RPM package support."
    exit 1
fi

# Creation des repertoires sources pour rpmbuild
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Copie des fichiers sources
cp ../obj/powerjoular ~/rpmbuild/SOURCES/
cp powerjoular.service ~/rpmbuild/SOURCES/

# Copie et préparation du fichier spec
cp powerjoular.spec ~/rpmbuild/SPECS/

# Construction du RPM
rpmbuild -ba ~/rpmbuild/SPECS/powerjoular.spec

# Verification et nettoyage
echo "Package RPM construit :"
find ~/rpmbuild/RPMS/ -type f -name "*.rpm"
