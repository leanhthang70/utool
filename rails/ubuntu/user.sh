#!/bin/bash

user_name=$1

sudo useradd $user_name
sudo usermod -aG sudo $user_name
