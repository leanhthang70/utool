#!/bin/bash

read -p "=> Type 1 add, 2 to change password, 3 remove user: " option
read -p "=> username: " user_name

if [ "$option" -eq 1  ]; then
  # Add a new user using sudo useradd
  sudo adduser $user_name
  sudo usermod -aG sudo $user_name
elif [ "$option" -eq 2 ]; then
  read -p "=> Password for $user_name: " new_pass
  read -p "=> Password confirmation: " confirm_pass
  if [ "$new_pass" == "$confirm_pass" ]; then
    # Change the password using sudo passwd
    echo "$user_name:$new_pass" | sudo chpasswd
    echo "Password for $user_name has been changed."
  else
    echo "Password confirmation does not match. Password not changed."
  fi
elif [ "$option" -eq 3 ]; then
  # Remove user using sudo userdel
  sudo userdel -r $user_name
else
  echo "Unknown option type. Please enter 1, 2 or 3 !"
fi

