#!/usr/bin/env bash

# shellcheck source=bin/common.sh
. "${BASH_SOURCE[0]%/*}/common.sh"

IFS=$'\n'

# See https://github.com/koalaman/shellcheck/wiki/SC2207 for this syntax.
docker_image_names=()
while IFS='' read -r line; do
  docker_image_names+=( "$line" )
done < <( cd "$yb_build_infra_root/docker_images" && ls )

unset IFS

print_usage() {
  cat <<EOT
Usage: ${0##*/} <options>
Options:
  -h, --help
    Print usage and exit
  -i, --image_name
    Image name to build.
    Available options: ${docker_image_names[*]}
  -p, --push
    Push the built image(s) to DockerHub (must be logged in).
EOT
}

# http://bit.ly/print_usage_to
if [[ $# -eq 0 ]]; then
  print_usage >&2
  exit 1
fi

image_name=""
should_push=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
    ;;
    -i|--image_name)
      image_name=$2
      shift
    ;;
    -p|--push)
      should_push=true
    ;;
    *)
      fatal "Unknown command: $1"
  esac
  shift
done


dockerfile_path=$yb_build_infra_root/docker_images/$image_name/Dockerfile

timestamp=$( get_timestamp_for_filenames )
tag=yugabytedb/yb_build_infra_$image_name:v${timestamp}_$USER

(
  set -x
  # We need to change to this directory to be able to reference scripts from docker_setup_scripts.
  cd "$yb_build_infra_root"
  docker build -f "$dockerfile_path" -t "$tag" .
)

if "$should_push"; then
  log "Pushing $tag to DockerHub (--push specified)."
  ( set -x; docker push "$tag" )
else
  log "Successfully built tag $tag. Specify --push to push to DockerHub."
fi

