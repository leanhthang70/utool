#!/bin/bash

echo "=== Install Image Processing ==="

sudo apt install libvips-dev -y
sudo apt install optipng -y
sudo apt install webp -y
sudo apt-get install cmake autoconf automake libtool nasm make pkg-config libpng-dev bzip2 -y
git clone https://github.com/mozilla/mozjpeg.git
cd mozjpeg
mkdir build && cd build
sudo cmake -G"Unix Makefiles" ../
sudo make install


