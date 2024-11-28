#!/bin/bash

# Pre-Validation Script for the MicroK8s Repository before it is built as a Snap Package.
# Listing all the Pre-validation checks that are required to be done before the Snap Package is built.
# 1.1 Checking if the Kube-Track in the Kubernetes Version is set, it proves the cherry pick and source code of the appropriate version needed was picked.
# 1.2 Checking if the Kubernetes Version is appropriately set to the build version that is needed.
# 2. Checking the appropriate Python Version in the snapcraft.yaml file.
# 3. Checking if the appropriate Golang Version is set in the snapcraft.yaml file, and checking if the Go version is present in the snap packages.
# 4. Checking if the appropriate Pause Image version is updated in the containerd.toml file and images.txt for build scripts.
# 5. Check if the GO-FIPS Variable, LD_LIBRARY PATH, and OpenSSL Variables are properly set and updated.

# Setting up the configuration file for the pre-validation scripts.
source $(pwd)/scripts/pre-validation/config.sh

# Exit the script upon the failure. 
set -e 

# Exit if any fails in case the script is used in a pipeline.
set -euo pipefail

# 0 Function to exit the script. 
exit_with_message() {
    local message="$1"
    local exit_code="${2:-1}" # Default exit code is 1.
    echo "$message" 
    exit "$exit_code"
}

# 0 Function to check some necessary tools present in the environment.
check_necessary_tools() {
    # Checking if yq is installed and configured in the environment.
    if ! command -v yq &> /dev/null; then
        exit_with_message "yq is not installed in the environment. Please install yq..." 
    else
        echo "yq is installed"
        echo $(yq --version) 
    fi
}

# 1.1 Checking if the Kube-Track in the Kubernetes Version is set, it proves the cherry pick and source code of the appropriate version needed was picked.
checking_kube_track() {
    # This check is done as the cherry pick is version based. The Kube-Track value is set in the version.sh file.
    # local kube_track=$(cat "${KUBERNETES_VERSION_PATH}" | grep -m 1 "KUBE_TRACK=" | cut -d "=" -f 2 | cut -d ":" -f 2 | cut -d "}" -f 1 | cut -d "-" -f 2 )
    local kube_track=$(grep -m 1 "KUBE_TRACK=" "${KUBERNETES_VERSION_PATH}" |  sed -E 's/.*:-([^"}]+)+.*/\1/')
    echo "Detected Kubernetes Version Tag -- $kube_track"
    if [[ "$kube_track" != $(echo "$KUBERNETES_VERSION" | cut -d "." -f 1,2) ]]; then 
        exit_with_message "The Kube-Track Value and Kubernetes Version does not match. Either the incorrect version tag or the cherry pick has an issue..?" 
    else
        echo "The Kube-Track Value is correct." 
    fi

}

# 1.2 Checking if the Kubernetes Version is appropriately set to the build version that is needed.
checking_kubernetes_version() {
    # The Kubernetes Version that is needed to build as a snap package is present in the build-scripts/components/kubernetes/version.sh file.
    # Replace the KUBERNETES_VERSION variable with appropriately value needed for the build.
    # local kubernetes_version=$(cat "${KUBERNETES_VERSION_PATH}" | grep -m 1 "KUBE_VERSION=" | cut -d "=" -f 2 | cut -d "v" -f 2)
    local kubernetes_version=$(grep -m 1 "KUBE_VERSION=" "$KUBERNETES_VERSION_PATH" | sed -E 's/.*=v(([0-9]+\.).*)/\1/') 
    echo "Detected Kuberenetes Version -- $kubernetes_version"
    if [[ "$kubernetes_version" != "$KUBERNETES_VERSION" ]]; then
        exit_with_message "The Kubernetes Version is not set correctly in the source code and the expected version. Please set it correctly..."
    else
        echo "The Kubernetes Version ${kubernetes_version} is set correctly."
    fi
}

# 2. Checking the appropriate Python Version in the snapcraft.yaml file.
checking_python_runtime_version() {
    # The Python Runtime Version is set in the snapcraft.yaml file.
    # This check is done to ensure that the rumtime version is not over-ridden. 
    check_file_exists $SNAP_YAML_PATH
    local python_version
    # python_version=$(yq -e '.parts.python-runtime.build-environment[0].C_INCLUDE_PATH' "$SNAP_YAML_PATH" | cut -d "/" -f 4 | awk -F 'python' '{print $2}')
    python_version=$(yq -e '.parts.python-runtime.build-environment[0].C_INCLUDE_PATH' "$SNAP_YAML_PATH" | sed -E 's/.*python(([0-9]+\.).*)/\1/')
    if [[ "$python_version" != "$DEFAULT_PYTHON_VERSION" ]]; then
        exit_with_message "Python Runtime Version is not set correctly in the snapcraft.yaml file..."
    else
        echo "Python Runtime Version is set correctly."
    fi
}

# 3. Checking if the appropriate Golang Version is set in the snapcraft.yaml file, and checking if the Go version is present in the snap packages.
check_go_version() {
    # The Go Version is set in two places, the snapcraft YAML file and in the snap info list.
    # The tracking section will be covering the latest stable FIPS Version. Only FIPS version will be looked into.
    local go_snap_version=$(snap info go | grep fips | awk 'NR==2 {print $1}' | sed -E 's/([0-9]+\.[0-9]+-fips).*/\1/')
    echo "Latest version of $go_snap_version"
    # Find the specified Go Version in the Snapcraft.yaml

    # The Go Version is set in the snapcraft.yaml file.
    local go_snapcraft_version=$(yq -e '.parts.build-deps.override-build' "$SNAP_YAML_PATH" | sed -E 's/.*--channel ([^ ]+).*/\1/' | sed '/^[[:space:]]*$/d' | head -n 1)
    echo "Detected Go Version -- $go_snapcraft_version"
    local go_snapcraft_packages_count=$(yq -e '.parts.build-deps.override-build' "$SNAP_YAML_PATH" | sed -E 's/.*--channel ([^ ]+).*/\1/' | sed '/^[[:space:]]*$/d' | uniq | wc -l)
    echo "Go Packages from the Snapcraft -- ${go_snapcraft_packages_count}"
    if [[ "$go_snapcraft_packages_count" -ne 1 ]]; then
        exit_with_message "There is more than one Go Version set in the snapcraft.yaml file. Please set only one valid Go-FIPS version..."
    fi

    # Check if the Go Version is correct.
    local go_version=$(echo $go_snapcraft_version | cut -d "/" -f 1)
    
    if [[ "$go_snap_version" != "$go_version" ]]; then
	    exit_with_message "The Go Version specified in the snapcraft.yaml file does not match with the version present in the Snap Packages. Please verify..." 1
    else
	    echo "$go_version matches with the version in the Snap Packages"
    fi
    
    if [[ "$go_version" != "$GO_FIPS_VERSION" ]]; then
        exit_with_message "The Go Version is not set correctly in the snapcraft.yaml file..."
    else
        echo "The Go Version is set correctly..."
    fi
}

# 4. Checking if the appropriate Pause Image version is updated in the containerd.toml file and images.txt for build scripts.
check_pause_image_version() {
    # The Pause Image Version is set in the containerd.toml file and in the build-scripts image.txt file.
    # This check is done to ensure the updated values are used, to prevent garbage collection in the containers.
    check_file_exists $CONTAINERD_TOML_FILE
    check_file_exists $IMAGES_LIST_FILE
    # local pause_containerd_image=$(cat $CONTAINERD_TOML_FILE | grep -m 1 "sandbox_image" | cut -d ":" -f 2 | cut -d "\"" -f 1)
    local pause_containerd_image=$(grep -m 1 "sandbox_image" "$CONTAINERD_TOML_FILE" | sed -E 's/.*pause:(([0-9]+\.)+.).*/\1/')
    echo "Pause Containerd Image Version -- $pause_containerd_image"
    if [[ "${pause_containerd_image}" != "${PAUSE_IMAGE_VERSION}" ]]; then
        exit_with_message "The Pause Image Version does not match the expected version. Please update in the ${CONTAINERD_TOML_FILE}..." 1
    else
        echo "The Pause Image Version for Containerd is correctly set..."
    fi

    # The similar check for the images.txt file.
    #local pause_image=$(cat $IMAGES_LIST_FILE | grep -i "pause" | cut -d ":" -f 2)
    local pause_image=$(grep -i "pause" "$IMAGES_LIST_FILE" | sed -E 's/.*:(([0-9]+\.)+.).*/\1/')
    echo "Pause Image Version -- $pause_image"
    if [[ "${pause_image}" != "${PAUSE_IMAGE_VERSION}" ]]; then
        exit_with_message "The Pause Image Version does not match the expected version. Please update in the ${IMAGES_LIST_FILE}..." 1
    else
        echo "The Pause Image Version for the build scripts is correctly set..."
    fi
}

# 5. Check if the GO-FIPS Variable, LD_LIBRARY PATH, and OpenSSL Variables are properly set and updated.
check_required_variables() {
    variables_list=("OPENSSL_EXECUTABLE" "OPENSSL_CONF" "LD_LIBRARY_PATH")
    for variable in "${variables_list[@]}"; do
        # Check if the variable assignment is commented out
        if grep -q "^[[:space:]]*#.*$variable[[:space:]]*=" "$FIPS_ENV_FILE"; then
            # If the variable is commented, exit with a message
            exit_with_message "The $variable is commented. Please uncomment the variable in the $FIPS_ENV_FILE file..." 1
        fi
    done

    # Checking the GOFIPS variable value
    local gofips=$(grep "^[^#]*GOFIPS=" "$FIPS_ENV_FILE" | cut -d '=' -f 2)
    if [[ ! $gofips -eq 1 ]]; then
	    exit_with_message "The GOFIPS Env variable is set to 0. Please update it..." 
    fi
    # If none of the variables are commented, print success
    echo "All variables are set correctly and not commented out."
}

main() {
    # Calling all the functions to perform the pre-validation checks.

    check_necessary_tools
    read_enhance
    checking_kube_track
    read_enhance
    checking_kubernetes_version
    read_enhance
    check_go_version
    read_enhance
    checking_python_runtime_version
    read_enhance
    check_pause_image_version
    check_required_variables
    read_enhance
}

main

