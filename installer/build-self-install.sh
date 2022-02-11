mkdir -p installer

makeself.sh ./powerjoular-bin ./installer/powerjoular-installer.sh "PowerJoular Installer" ./install.sh

sha512sum powerjoular-installer.sh > ./installer/sha512-checksum-powerjoular-installer
