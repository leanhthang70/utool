#!/bin/bash

if [ $# -ne 1 ]; then
echo "Usage: $0 param1 param2"
exit 1
fi

domain_name=$1

echo "Param 1: $domain_name"
