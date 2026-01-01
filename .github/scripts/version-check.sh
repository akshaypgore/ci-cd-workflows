#!/bin/bash

version_set=$1
current_prod_version=$2
string_check="SNAPSHOT"

if [[ "$version_set" == *"$string_check"* ]]; then
    echo "Version Deployed is $(echo $version_set)"
else
    echo "Please version the change as snapshot"
    exit 1
fi

version_to_test=$(echo $version_set | awk -F '-' '{print $1}')

if [[ "printf '%s\n' "$version_to_test" "$current_prod_version" | sort -V | head -n 1" == "$version_to_test" ]]; then
    echo "Version set is less than or equal to version in prod. Please bump the version"
    exit 1
else
    echo "Good to go ahead"
fi
