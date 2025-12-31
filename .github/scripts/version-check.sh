#!/bin/bash

version_set=$1
current_prod_version=$2
string_check="SNAP"
echo "${version_set}"
echo "${current_prod_version}"

if [[ "$version_set" == *"$string_check"* ]]; then
    echo "Found it!"
else
    echo " no Found it!"
fi

echo "Versions used ahead"
echo "${version_set}"
echo "${current_prod_version}"
