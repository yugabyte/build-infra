#!/usr/bin/env bash

# Setup shared between multiple systems

set -euo pipefail

echo "::group::Creating the yugabyteci user"
if [[ $OSTYPE == linux* ]]; then
  if [[ -f /etc/redhat-release ]]; then
    adduser yugabyteci
  else
    adduser --disabled-password --gecos "" yugabyteci
  fi
fi
echo "::endgroup::"

cd "${BASH_SOURCE[0]%/*}"

echo "::group::Creating the /opt/yb-build directory hierarchy"
bash ./create_opt_yb-build_dirs.sh
echo "::endgroup::"

# These scripts might not executable once copied into the Docker container.
echo "::group::Installing the hub tool for interacting with GitHub"
bash ./install_hub_tool.sh
echo "::endgroup::"

echo "::group::Instaling the Ninja build system"
bash ./install_ninja.sh
echo "::endgroup::"

echo "::group::Installing shellcheck"
bash ./install_shellcheck.sh
echo "::endgroup::"
