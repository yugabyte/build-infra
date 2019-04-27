#!/usr/bi/env bash
set -euo pipefail

if [[ $BASH_SOURCE == $0 ]]; then
  echo "$BASH_SOURCE must be sourced, not executed" >&2
  exit 1
fi

yb_build_infra_root=$( cd "${BASH_SOURCE%/*}" && cd .. && pwd )
if [[ ! -d $yb_build_infra_root/yugabyte-bash-common ]]; then
  git submodule update --init --recursive
fi

. "$yb_build_infra_root"/yugabyte-bash-common/src/yugabyte-bash-common.sh
