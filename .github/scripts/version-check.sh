#!/bin/bash

version_set=$1
current_prod_version=$2
echo "${version_set}"
echo "${current_prod_version}"

if [[ ${version_set} =~ "-SNAPSHOT" ]]; then
    echo "Please add snapshot"
    exit 1
else
    exit 0
fi

echo "Versions used ahead"
echo "${version_set}"
echo "${current_prod_version}"