#!/bin/bash

WIN_SUBLIME_PATH="alias subl='/mnt/c/Program\ Files/Sublime\ Text\ 3/subl.exe'"
grep -v "$WIN_SUBLIME_PATH" ~/.bashrc > temp_file && mv temp_file ~/.bashrc
sleep 1
echo "$WIN_SUBLIME_PATH" | sudo tee -a ~/.bashrc

WIN_VSCOED_PATH="/mnt/c/Users/lat/AppData/Local/Programs/Microsoft\ VS\ Code/code.exe"
grep -v "$WIN_VSCOED_PATH" ~/.bashrc > temp_file && mv temp_file ~/.bashrc
sleep 1
echo "$WIN_VSCOED_PATH" | sudo tee -a ~/.bashrc
