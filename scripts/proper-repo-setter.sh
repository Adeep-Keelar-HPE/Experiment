#!/bin/bash

# This script is used to set up the official repository of the Microk8s Project, and sync the changes of our repository in order to build the snap package.
# Why are we doing this ?
# During build of snap package (in VM and in the container), our repository does not have the .git directory, which is causing the snap package build to fail at bom stage.
# To avoid this, let us set up the official repository, and sync our changes to the official repository, and build the snap package using that.

# Variables that will be useful.
OFFICIAL_REPO="https://github.com/canonical/microk8s.git"

# Helper function to check if the pre-requisites are done.
function check_prerequisites() {
    # Check if git is installed.
    if ! command -v git &> /dev/null; then
        echo "git is not installed in the environment. Please install git..."
        exit 1
    else
        echo "git is installed"
        echo $(git --version)
    fi
}

# Function to setup the official repository.
function setup_official_repo() {
    # Clone the official repository. 
    git clone $OFFICIAL_REPO
}

check_prerequisites
setup_official_repo