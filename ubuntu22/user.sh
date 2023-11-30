#!/bin/bash

read -p "=> Nhập user mới: " user_name

sudo useradd $user_name
sudo usermod -aG sudo $user_name
