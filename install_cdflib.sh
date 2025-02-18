cd /tmp
wget https://spdf.gsfc.nasa.gov/pub/software/cdf/dist/cdf38_1/linux/cdf38_1-dist-cdf.tar.gz
tar xzf cdf38_1-dist-cdf.tar.gz; rm cdf38_1-dist-cdf.tar.gz; cd cdf38_1-dist; 
make OS=linux ENV=gnu SHARED=yes CURSES=no FORTRAN=no all; 
make INSTALLDIR=/usr/lib64/cdf install.lib install.definitions;
echo "/usr/lib64/cdf" > /etc/ld.so.conf.d/cdf.conf
ldconfig
