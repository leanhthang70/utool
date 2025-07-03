#!/bin/bash

read -p "=> Enter your email: " email

echo "Generate SSH key"
ssh-keygen -t ed25519 -C "your_email@example.com"
