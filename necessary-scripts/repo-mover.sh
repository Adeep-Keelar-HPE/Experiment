#!/bin/bash

# This script is used to move the contents of repo to another repository.
# Move the contents of microk8s-src to the base directory (root)
mv microk8s-src/* .
rm -rf microk8s-src/