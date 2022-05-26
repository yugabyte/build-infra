#!/usr/bin/env bash

set -euo pipefail -x

# Instructions from https://github.com/koalaman/shellcheck

scversion="stable" # or "v0.4.7", or "latest"
wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.linux.$( uname -m ).tar.xz" | tar -xJv
cp "shellcheck-${scversion}/shellcheck" /usr/bin/
shellcheck --version
