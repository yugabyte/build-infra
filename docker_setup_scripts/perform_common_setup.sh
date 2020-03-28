#!/usr/bin/env bash

# Setup shared between multiple systems

set -euo pipefail

if [[ $OSTYPE == linux* ]]; then
  adduser --disabled-password --gecos "" yugabyteci
fi

cd "${BASH_SOURCE[0]%/*}"

# These scripts might not executable once copied into the Docker container.
bash ./install_hub_tool.sh
bash ./install_ninja.sh
bash ./install_shellcheck.sh
