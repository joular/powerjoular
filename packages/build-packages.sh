# Build RPM package
fpm -t rpm -p powerjoular-0.1.0-x86_64.rpm

# Build DEB package
fpm -t deb -p powerjoular-0.1.0-x86_64.deb
