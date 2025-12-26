#!/usr/bin/env bash

set -euo pipefail -x


arc_version='origin/stable'

git clone -b "$arc_version" https://github.com/phorgeit/arcanist.git arcanist
git clone https://github.com/yugabyte/arcanist-support.git arcanist-support

arcanist/bin/arc set-config load '["arcanist-support/src"]'

mkdir -p .config
cat << EOF > .config/pycodestyle_config.ini
[pep8]
max-line-length = 100

[pycodestyle]
max-line-length = 100
EOF
