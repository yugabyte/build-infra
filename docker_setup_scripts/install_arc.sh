#!/usr/bin/env bash

set -euo pipefail -x


arc_version='stable'
bld_user_dir='/home/yugabyteci'

git clone -b "$arc_version" https://github.com/phorgeit/arcanist.git "${bld_user_dir}/arcanist"
git clone https://github.com/yugabyte/arcanist-support.git "${bld_user_dir}/arcanist-support"

arcanist/bin/arc set-config load '["arcanist-support/src"]'

mkdir -p $bld_user_dir/.config
cat << EOF > $bld_user_dir/.config/pycodestyle_config.ini
[pep8]
max-line-length = 100

[pycodestyle]
max-line-length = 100
EOF

# Some places have path of dependent tool hard-coded
if [[ ! -e "/usr/local/bin/pycodestyle" ]]; then
  ln -s "/usr/bin/pycodestyle" "/usr/local/bin/pycodestyle"
fi
