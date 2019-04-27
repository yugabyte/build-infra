#!/usr/bin/env bash

. "${BASH_SOURCE%/*}/common.sh"

IFS=$'\n'
docker_image_names=( $( cd "$yb_build_infra_root/docker_images" && ls ) )
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
  docker build -f "$dockerfile_path" -t "$tag" .
  docker push "$tag"
)
