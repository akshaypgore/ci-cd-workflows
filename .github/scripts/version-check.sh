#!/bin/bash

version_set=$1
current_prod_version=$2
string_check="SNAPSHOT"
# echo "${version_set}"
# echo "${current_prod_version}"

if [[ "$version_set" == *"$string_check"* ]]; then
    echo "Version Deployed is $(echo $version_set | awk -F '-' '{print $2}')"
else
    echo " no Found it!"
fi
