#!/bin/bash

echo "=== Install Image Processing ==="
sudo apt update

sudo apt install libvips-dev -y
sudo apt install optipng -y
sudo apt install webp -y
sudo apt-get install cmake autoconf automake libtool nasm make pkg-config libpng-dev bzip2 -y
sudo apt-get install advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush pngquant -y

# mozjpeg
cd
git clone https://github.com/mozilla/mozjpeg.git
cd mozjpeg
mkdir build && cd build
sudo cmake -G "Unix Makefiles" ../
sudo make install

# ImageMagick
echo "=== Install ImageMagick ==="
read -p "=> Do you want to install ImageMagick? Yes(y): " option
if [ "$option" == "y" ]; then
  sudo apt install imagemagick -y

  sudo apt install ffmpeg -y
fi
