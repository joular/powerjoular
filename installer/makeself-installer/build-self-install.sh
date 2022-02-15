cd ../../

# Create obj/ folder it not exist
mkdir -p obj

# First build the project with gprbuild
gprbuild powerjoular.gpr

cd installer

cp -f ../obj/powerjoular ./makeself-installer/powerjoular-bin/powerjoular
cp -f ../systemd/powerjoular.service ./makeself-installer/powerjoular-bin/powerjoular.service

cd makeself-installer

mkdir -p installer

makeself ./powerjoular-bin ./installer/powerjoular-installer.sh "PowerJoular Installer" ./install.sh

sha512sum ./installer/powerjoular-installer.sh > ./installer/sha512-checksum-powerjoular-installer
