#!/usr/bi/env bash

# Copyright (c) Yugabyte, Inc.

set -euo pipefail

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  echo "${BASH_SOURCE[0]} must be sourced, not executed" >&2
  exit 1
fi

readonly yb_build_infra_root=$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd )
if [[ ! -d $yb_build_infra_root/yugabyte-bash-common ||
      -z $( ls -A "$yb_build_infra_root/yugabyte-bash-common" ) ]]; then
  ( cd "$yb_build_infra_root"; git submodule update --init --recursive )
fi

# shellcheck source=yugabyte-bash-common/src/yugabyte-bash-common.sh
. "$yb_build_infra_root"/yugabyte-bash-common/src/yugabyte-bash-common.sh
