#!/bin/bash

read -p "=> Type 1 to add a user and 2 to change the password: " option
read -p "=> username: " user_name
read -p "=> Password for $username: " new_pass
read -p "=> Password confirmation: " confirm_pass

if [ "$option" -eq 2  ]; then
  sudo useradd $user_name
  sudo usermod -aG sudo $user_name
elif [ "$option" -eq 2 ]; then
  if [ "$new_pass" == "$confirm_pass" ]; then
    # Change the password using sudo passwd
    echo "$user_name:$new_pass" | sudo chpasswd
    echo "Password for $user_name has been changed."
  else
    echo "Password confirmation does not match. Password not changed."
  fi
else
  echo "Unknown option type. Please enter 1 or 2 !"
fi

