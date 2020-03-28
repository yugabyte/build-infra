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

echo "::group::Creating the /opt/yb-build directory hierarchy"
for dir_name in brew download_cache thirdparty tmp; do
  dir_path=/opt/yb-build/$dir_name
  mkdir -p "$dir_path"
  chmod 777 "$dir_path"
fi
chmod 777 /opt/yb-build
echo "::endgroup::"

cd "${BASH_SOURCE[0]%/*}"

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
