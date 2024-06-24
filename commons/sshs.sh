#!/bin/bash

read -p "=> Enter your email: " email

echo "Generate SSH key"
ssh-keygen -t ed25519 -f /path/to/your/key
