#!/bin/bash

KUBE_TRACK="${KUBE_TRACK:-1.31}"            # example: "1.24"
KUBE_VERSION=v1.31.3

if [ -z "${KUBE_VERSION}" ]; then
  if [ -z "${KUBE_TRACK}" ]; then
    KUBE_VERSION="$(curl -L --silent "https://dl.k8s.io/release/stable.txt")"
  else
    KUBE_TRACK="${KUBE_TRACK#v}"
    KUBE_VERSION="$(curl -L --silent "https://dl.k8s.io/release/stable-${KUBE_TRACK}.txt")"
  fi
fi

echo "${KUBE_VERSION}"
