#!/usr/bin/env bash

set -euo pipefail

for dir_name in brew download_cache thirdparty tmp; do
  dir_path=/opt/yb-build/$dir_name
  ( 
    set -x
    mkdir -p "$dir_path"
    chmod 777 "$dir_path"
  )
done

set -x
chmod 777 /opt/yb-build