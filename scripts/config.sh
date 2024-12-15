#!/bin/bash

# This is the configuration file for the pre-validation scripts.
# All of the hard-coded values and settings are present in this file.

# Adding the user-argument check for the Kubernetes Version.
if [ $# -eq 0 ]; then
    echo "No Kubernetes Version or Action type is provided..."
    echo "$0 <Kubernetes Version> <action-type>"
    exit 1
fi

# Arguments 
Kubernetes_arg=$1
Action_type=$2

# The Action Type will specify the type of pre-validation will be performed.
# Is it pre-repo or post-repo ?
if [ "$Action_type" != "pre-repo" ] && [ "$Action_type" != "post-repo" ]; then
    echo "Invalid Action Type provided..."
    echo "Action type should be either pre-repo or post-repo..."
    exit 1
fi

BASE_PATH=$(pwd)
if [ "$Action_type" == "pre-repo" ]; then
    SOURCE_PATH="$BASE_PATH/microk8s-src"
else
    SOURCE_PATH="$BASE_PATH/microk8s"
fi
SCRIPT_PATH="$BASE_PATH/scripts"
INFO_JSON="$SCRIPT_PATH/info.json"


KUBERNETES_VERSION_PATH="$SOURCE_PATH/build-scripts/components/kubernetes/version.sh"
SNAP_YAML_PATH="$SOURCE_PATH/snap/snapcraft.yaml"
CONTAINERD_TOML_FILE="$SOURCE_PATH/microk8s-resources/default-args/containerd-template.toml"
IMAGES_LIST_FILE="$SOURCE_PATH/build-scripts/images.txt"
FIPS_ENV_FILE="$SOURCE_PATH/microk8s-resources/default-args/fips-env"
KUBE_APISERVER_FILE="$SOURCE_PATH/microk8s-resources/default-args/kube-apiserver"

# COMPONENTS VERSIONS FILE-PATHS
MICROK8S_HELM_PATH="$SOURCE_PATH/build-scripts/components/helm/version.sh"
MICROK8S_DQLITE_PATH="$SOURCE_PATH/build-scripts/components/k8s-dqlite/version.sh"
MICROK8S_CONTAINERD_PATH="$SOURCE_PATH/build-scripts/components/containerd/version.sh"
MICROK8S_ETCD_PATH="$SOURCE_PATH/build-scripts/components/etcd/version.sh"

# Check if jq is installed.
check_jq_exists() {
    # Checking if jq is installed and configured in the environment.
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed in the environment. Please install jq..." 
        exit 1
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
            export DEFAULT_PYTHON_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"Python_Version\"" "$INFO_JSON")
            export PAUSE_IMAGE_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"Pause_Image_Version\"" "$INFO_JSON")
            export ETCD_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"ETCD_Version\"" "$INFO_JSON")
            export CONTAINERD_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"Containerd_Version\"" "$INFO_JSON")
            export DQLITE_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"K8s_dqlite_Version\"" "$INFO_JSON")
            export HELM_VERSION=$(jq -r ".\"microk8s_version\".\"$kubernetes_version\".\"Helm_Version\"" "$INFO_JSON")
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
read_enhance
parse_kubernetes_version $Kubernetes_arg
read_enhance
