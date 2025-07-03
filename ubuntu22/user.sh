#!/bin/bash

# Save original directory
ORIGINAL_DIR="$(pwd)"

read -p "=> Type 1 add, 2 to change password, 3 remove user: " option
read -p "=> username: " user_name

if [ "$option" -eq 1  ]; then
  # Add a new user using sudo useradd
  sudo adduser $user_name
  sudo usermod -aG sudo $user_name
elif [ "$option" -eq 2 ]; then
  sudo passwd $user_name
elif [ "$option" -eq 3 ]; then
  # Remove user using sudo userdel
  sudo userdel -r $user_name
else
  echo "Unknown option type. Please enter 1 or 2 !"
fi

# Return to original directory
if [[ -n "$ORIGINAL_DIR" && -d "$ORIGINAL_DIR" ]]; then
    cd "$ORIGINAL_DIR"
    echo "Returned to original directory: $ORIGINAL_DIR"
fi
