#!/bin/bash

kubernetes_version=$1
snap_package="microk8s-fips.snap"
date_value=$(date +"%b_%d_%Y")

new_snap_package_name="microk8s-fips-v$kubernetes_version"_"$date_value"_amd.snap

checksum_sha=$(sha256sum microk8s-fips.snap | awk '{print $1}')

# Generate json file.
cat << EOF > info.json
{
  "microk8s_version": "$kubernetes_version",
  "$new_snap_package_name": "$checksum_sha"
}
EOF