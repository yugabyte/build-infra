#!/usr/bin/env bash

# shellcheck source=bin/yb_build_infra_common.sh
. "${BASH_SOURCE[0]%/*}/yb_build_infra_common.sh"

cd "$yb_build_infra_root"
while IFS= read -r script_path; do
  echo "Checking $script_path"
  shellcheck -x "$script_path"
done < <(find . -name "*.sh" -and -not -wholename "./yugabyte-bash-common/*" )

echo "ALL CHECKS SUCCESSFUL"
