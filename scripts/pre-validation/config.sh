#!/bin/bash

# This is the configuration file for the pre-validation scripts.
# All of the hard-coded values and settings are present in this file.

BASE_PATH=$(pwd)
SRC_PATH="$BASE_PATH/Experiment"

KUBERNETES_PACKAGE="microk8s-src"
KUBERNETES_VERSION_PATH="${SRC_PATH}/${KUBERNETES_PACKAGE}/build-scripts/components/kubernetes/version.sh"
SNAP_YAML_PATH="${SRC_PATH}/${KUBERNETES_PACKAGE}/snap/snapcraft.yaml"
CONTAINERD_TOML_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/containerd-template.toml"
IMAGES_LIST_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/build-scripts/images.txt"
FIPS_ENV_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/fips-env"
KUBE_APISERVER_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/kube-apiserver"

KUBERNETES_VERSION="1.29.10" # Don't forget to change it here for every update.
DEFAULT_PYTHON_VERSION="3.8" # Change this when the Python Version is Updated in the future builds (legit for 1.30, 1.31)
PAUSE_IMAGE_VERSION="3.9" # Change this when the Pause Image Version is Updated in the future builds.
GO_FIPS_VERSION="1.21-fips"

# Common Function to check the existence of a file.
check_file_exists() {
    # This function needs an argument to be passed.
    if [[ $# -eq 0 ]]; then
        echo "File path not provided."
        exit 1
    fi

    local file_path="$1"

    # Check if the file exists.
    if [[ ! -f "$file_path" ]]; then
        echo "File does not exist..."
        exit 1
    fi
}

# Common Function to add more visibility to the logs.
read_enhance() {
	echo "===================================================="
}
