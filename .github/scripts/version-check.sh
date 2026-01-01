#!/bin/bash

version_set=$1
current_prod_version=$2
string_check="SNAPSHOT"
# echo "${version_set}"
# echo "${current_prod_version}"

if [[ "$version_set" == *"$string_check"* ]]; then
    echo "Version Deployed is $(echo $version_set | awk -F '-' '{print $2}')"
else
    echo "Please version the change as snapshot"
    exit 1
fi

if [[ "printf '%s\n' '$(echo $version_set | awk -F "-" "{print $1}")' '$current_prod_version'|sort -V|head -n 1" == "$version_set" ]]; then
    echo "Version set is less than or equal to version in prod. Please bump the version"
    exit 1
else
    echo "Good to go ahead"
fi
