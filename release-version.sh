#!/bin/bash

# Build the Linux packages (deb and rpm) from binaries built elsewhere
#
# Nothing is compiled here. The binaries come from the build workflow, which compiles each
# architecture on a runner of that architecture, so nothing is cross compiled and nothing
# depends on a cross toolchain being installed on this machine.
#
# PowerJoular is built against more than one C library: a binary runs on the version of glibc it was built against or a newer one, and no older, so the build made on the newest system does not start on an older one. Every binary carries the version it needs in its name, and so do the packages made from it, and this script works that version out of the binary itself rather than being told: whatever the workflow was built on, the name says what the file actually needs.
#
# Usage:
#   ./release-version.sh [dir]
#
# [dir] holds one folder per build, laid out the way the build workflow uploads them:
#   <dir>/powerjoular-linux-amd64-glibc-2.35/powerjoular-glibc-2.35
#   <dir>/powerjoular-linux-aarch64-glibc-2.35/powerjoular-glibc-2.35
#   <dir>/powerjoular-linux-amd64-glibc-2.34/powerjoular-glibc-2.34
#   <dir>/powerjoular-linux-aarch64-glibc-2.34/powerjoular-glibc-2.34
# It defaults to ./artifacts
#
# The folder is only searched for binaries: how the folders are named and how many C library
# versions are in there is worked out from what is found, so adding another build needs no change here
#
# Download them from a run of the build workflow with the GitHub CLI:
#   gh run download <run-id> --pattern 'powerjoular-linux-*' --dir artifacts

# Stop at the first thing that goes wrong
# Without this, a missing binary carries on to the packaging steps, which then happily
# produce a package with nothing inside it
set -euo pipefail

cd "$(dirname "$0")"

BINARIES_DIR="${1:-artifacts}"


# Check what is needed is here

# objdump reads the architecture and the C library versions out of a binary, and comes with binutils
for TOOL in dpkg-deb rpmbuild objdump; do
    if ! command -v "$TOOL" > /dev/null 2>&1; then
        echo "ERROR: $TOOL is not installed." >&2
        echo "On Debian and Ubuntu: sudo apt install dpkg-dev rpm binutils" >&2
        echo "On Fedora and AlmaLinux: sudo dnf install dpkg rpm-build binutils" >&2
        exit 1
    fi
done

if [[ ! -d "$BINARIES_DIR" ]]; then
    echo "ERROR: no such folder: $BINARIES_DIR" >&2
    echo "Usage: $0 [dir]   (default: artifacts)" >&2
    echo "It holds the binary folders the build workflow uploads, one per architecture and C library." >&2
    echo "Download them with: gh run download <run-id> --pattern 'powerjoular-linux-*' --dir artifacts" >&2
    exit 1
fi


# The version

# The one place the version is written down is the Alire manifest, and the rpm spec carries its own
# copy that rpmbuild reads straight out of the file, so the two are checked against each other here
# rather than left to drift into a release where the deb and the rpm disagree
VERSION=$(sed -n 's/^version *= *"\(.*\)"/\1/p' alire.toml | head -1)

if [[ -z "$VERSION" ]]; then
    echo "ERROR: no version found in alire.toml" >&2
    exit 1
fi

SPEC_VERSION=$(sed -n 's/^Version: *//p' installer/powerjoular.spec | head -1 | tr -d '[:space:]')

if [[ "$SPEC_VERSION" != "$VERSION" ]]; then
    echo "ERROR: alire.toml says $VERSION but installer/powerjoular.spec says $SPEC_VERSION" >&2
    echo "Make the two agree before building the packages." >&2
    exit 1
fi


# What each binary is

# The architecture the binary was built for, in the names rpm uses
# GNU binutils and the LLVM objdump word this differently, hence the two spellings of the same thing
architecture_of () {
    case "$(objdump -f "$1" 2> /dev/null | sed -n 's/.*architecture: *\([^,]*\).*/\1/p')" in
        i386:x86-64 | x86_64) echo "x86_64" ;;
        aarch64*) echo "aarch64" ;;
        *) echo "" ;;
    esac
}

# The oldest C library the binary runs against, which is the newest version any of its symbols asks for
# A binary linked fully static asks for none at all, and runs anywhere
c_library_of () {
    local FOUND
    FOUND=$(objdump -T "$1" 2> /dev/null | grep -o 'GLIBC_[0-9][0-9.]*' | sed 's/GLIBC_//' | sort -V | tail -1)

    if [[ -z "$FOUND" ]]; then
        echo "static"
    else
        echo "$FOUND"
    fi
}

# Whether the file is a binary at all, rather than a readme or a checksum sitting next to one
is_elf () {
    [[ "$(head -c 4 "$1" 2> /dev/null | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]
}


# Collect the binaries

rm -rf binary
mkdir -p binary

# One record per binary found: "<c library> <architecture>"
FOUND_LIST=""

while IFS= read -r BIN; do
    is_elf "$BIN" || continue

    ARCH=$(architecture_of "$BIN")
    GLIBC=$(c_library_of "$BIN")

    if [[ -z "$ARCH" ]]; then
        echo "Skipping $BIN: not built for an architecture the packages cover"
        continue
    fi

    if [[ -e "binary/$GLIBC/$ARCH/powerjoular" ]]; then
        echo "ERROR: two binaries for $ARCH against glibc $GLIBC, the second one is $BIN" >&2
        exit 1
    fi

    mkdir -p "binary/$GLIBC/$ARCH"
    cp "$BIN" "binary/$GLIBC/$ARCH/powerjoular"
    chmod 755 "binary/$GLIBC/$ARCH/powerjoular"

    echo "  found $ARCH against glibc $GLIBC  ($BIN)"
    FOUND_LIST="$FOUND_LIST$GLIBC $ARCH"$'\n'
done < <(find "$BINARIES_DIR" -type f | sort)

if [[ -z "$FOUND_LIST" ]]; then
    echo "ERROR: no binary found under $BINARIES_DIR" >&2
    exit 1
fi

echo "Packaging PowerJoular $VERSION"

# Create packages folder
rm -rf packages
mkdir -p packages

rm -rf deb-temp rpm-temp
mkdir -p deb-temp rpm-temp

while read -r GLIBC ARCH; do
    [[ -n "$GLIBC" ]] || continue

    BIN="$PWD/binary/$GLIBC/$ARCH/powerjoular"

    # The name every file of this build carries, so a machine can be given the one that runs on it
    LABEL="powerjoular-glibc-$GLIBC"


    # The deb package

    # The names dpkg itself uses: a package built for "aarch64" is one no arm64 machine will install
    case "$ARCH" in
        x86_64) DEB_ARCH="amd64" ;;
        aarch64) DEB_ARCH="arm64" ;;
    esac

    STAGE="deb-temp/$GLIBC-$DEB_ARCH"
    rm -rf "$STAGE"
    mkdir -p "$STAGE/powerjoular/usr/bin"
    mkdir -p "$STAGE/powerjoular/usr/lib/systemd/system"
    mkdir -p "$STAGE/powerjoular/DEBIAN"
    chmod 755 "$STAGE"

    # The binary is installed under its plain name: the C library version belongs on the file being downloaded, to tell the builds apart, and not on the command the machine ends up running
    install -m 755 "$BIN" "$STAGE/powerjoular/usr/bin/powerjoular"
    install -m 644 systemd/powerjoular.service "$STAGE/powerjoular/usr/lib/systemd/system/"

    # What the package asks of the machine is what the binary itself asks of it
    # A fully static binary asks for no C library at all
    if [[ "$GLIBC" == "static" ]]; then
        LIBC_DEPENDS="Depends: "
    else
        LIBC_DEPENDS="Depends: libc6 (>= $GLIBC)"
    fi

    # The package is called powerjoular whichever build it came from, so it installs, upgrades and
    # is removed the usual way, and two of these can never sit on one machine fighting over /usr/bin/powerjoular
    cat << EOL > "$STAGE/powerjoular/DEBIAN/control"
Package: powerjoular
Version: $VERSION
Maintainer: Adel Noureddine <adel.noureddine@outlook.com>
Architecture: $DEB_ARCH
Section: utils
Priority: optional
$LIBC_DEPENDS
Homepage: https://github.com/joular/powerjoular
Description: Monitor the power consumption of hardware components, processes and software.
 PowerJoular monitors, in real time, the power consumption of the CPU and the
 GPU of the machine, and of one process or one application running on it.
 It exports the power data to the terminal, to CSV files, and to a shared
 memory ring buffer.
 .
 This build runs against glibc $GLIBC and newer.
EOL

    ( cd "$STAGE" && dpkg-deb --build powerjoular > /dev/null )
    mv "$STAGE/powerjoular.deb" "packages/${LABEL}_${VERSION}_${DEB_ARCH}.deb"


    # The rpm package

    TOP="$PWD/rpm-temp/$GLIBC-$ARCH/rpmbuild"
    rm -rf "$TOP"
    mkdir -p "$TOP"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    cp installer/powerjoular.spec "$TOP/SPECS/"
    cp "$BIN" "$TOP/SOURCES/powerjoular"
    cp systemd/powerjoular.service "$TOP/SOURCES/"

    rpmbuild -bb "$TOP/SPECS/powerjoular.spec" \
        --define "_topdir $TOP" \
        --target "$ARCH" > /dev/null

    find "$TOP/RPMS" -name '*.rpm' | while IFS= read -r RPM; do
        mv "$RPM" "packages/${LABEL}-${VERSION}-1.${ARCH}.rpm"
    done
done <<< "$FOUND_LIST"

# Remove temp folders
rm -rf deb-temp rpm-temp

echo
echo "Packages for PowerJoular $VERSION:"
ls -1 packages | sed 's/^/  /'
