make clean

./autogen.sh
./configure --with-incompatible-bdb --with-gui=no --disable-tests --disable-man
make -j 8
make install