# Copy binary from obj to x86_64 folder
cp ../obj/powerjoular ./x86_64/

# Generate cheksum
sha512sum ./x86_64/powerjoular > ./x86_64/sha-512-checksum

# Build RPM package
fpm -t rpm -p powerjoular-$1-x86_64.rpm

# Build DEB package
fpm -t deb -p powerjoular-$1-x86_64.deb
