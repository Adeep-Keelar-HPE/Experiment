#!/bin/bash

kubernetes_version=$1
snap_name=$2
checksum_sha=$(sha256sum $snap_name | awk '{print $1}')

# Generate json file.
cat << EOF > info.json
{
  "microk8s_version": "$kubernetes_version",
  "$snap_name": "$checksum_sha"
}
EOF
