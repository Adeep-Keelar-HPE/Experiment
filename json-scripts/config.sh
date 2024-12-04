#!/bin/bash

# This is the configuration file for the pre-validation scripts.
# All of the hard-coded values and settings are present in this file.

BASE_PATH=$(pwd)
SRC_PATH="$BASE_PATH/Experiment"

INFO_JSON="info.json"
KUBERNETES_PACKAGE="microk8s-src"
KUBERNETES_VERSION_PATH="${SRC_PATH}/${KUBERNETES_PACKAGE}/build-scripts/components/kubernetes/version.sh"
SNAP_YAML_PATH="${SRC_PATH}/${KUBERNETES_PACKAGE}/snap/snapcraft.yaml"
CONTAINERD_TOML_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/containerd-template.toml"
IMAGES_LIST_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/build-scripts/images.txt"
FIPS_ENV_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/fips-env"
KUBE_APISERVER_FILE="${SRC_PATH}/${KUBERNETES_PACKAGE}/microk8s-resources/default-args/kube-apiserver"

# Adding the user-argument check for the Kubernetes Version.
if [ $# -eq 0 ]; then
    echo "No Kubernetes Version is provided..."
    echo "$0 <Kubernetes Version>"
    exit 1
fi

# Arguments 
Kubernetes_arg=$1

# Check if jq is installed.
check_jq_exists() {
    # Checking if jq is installed and configured in the environment.
    if ! command -v jq &> /dev/null; then
        exit_with_message "jq is not installed in the environment. Please install jq..." 
    else
        echo "jq is installed"
        echo $(jq --version) 
    fi
}

# Function to parse the Kubernetes version. 
parse_kubernetes_version() {
    # Extract the main version, while keeping the minor version intact.
    local whole_version=$1
    local minor_version=$1

    # Extract the Kubernetes version.
    local kubernetes_version=$(cut -d '.' -f 1,2 <<< $whole_version)
    
    # Check if the Kubernetes version is actually present in the info.json file.
    if jq -e ".\"microk8s_version\".\"$kubernetes_version\"" "$INFO_JSON" > /dev/null; then
        # Check if the minor_version is present in the list of versions
        if jq -r ".\"microk8s_version\".\"$kubernetes_version\".version[]" "$INFO_JSON" | grep -q "^$minor_version$"; then
            echo "Kubernetes Version $minor_version is present..."
            echo "Exporting values..."
            export KUBERNETES_VERSION=$minor_version
            export DEFAULT_PYTHON_VERSION=$(jq -e ".\"microk8s_version\".\"$kubernetes_version\".\"Python_Version\"" "$INFO_JSON")
            export PAUSE_IMAGE_VERSION=$(jq -e ".\"microk8s_version\".\"$kubernetes_version\".\"Pause_Image_Version\"" "$INFO_JSON")
            export GO_FIPS_VERSION=$(jq -e ".\"microk8s_version\".\"$kubernetes_version\".\"Go_FIPS_Version\"" "$INFO_JSON")
        else
            echo "Kubernetes Version $minor_version is not present"
            exit 1
        fi
    else
        echo "Kubernetes version $kubernetes_version is incorrect"
        exit 1
    fi

}

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

check_jq_exists
parse_kubernetes_version $Kubernetes_arg