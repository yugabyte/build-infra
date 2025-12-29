#!/usr/bin/env bash

set -euo pipefail -x

readonly RUST_VERSION=1.89.0 # This is the latest at the time of edit

install_dependencies() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "$ID" in
      amzn|rhel|centos|almalinux|fedora)
        yum install -y gcc && yum clean all
        ;;
      ubuntu|debian)
        apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
        ;;
      *)
        echo "Unsupported distribution: $ID"
        exit 1
        ;;
    esac
  else
    echo "Unsupported distribution: unknown"
    exit 1
  fi
}

install_dependencies

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_VERSION"
# This is a hack to get around inconsistent user at build time (yugabyte-db vs yugabyte-db-thirdparty)
# - yugabyte-db-thirdparty uses root
# - yugabyte-db uses yugabyteci
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u yugabyteci sh -s -- -y --default-toolchain "$RUST_VERSION"

# shellcheck disable=SC1091
source "$HOME/.cargo/env"
