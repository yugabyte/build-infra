#!/usr/bin/env bash

# shellcheck source=bin/yb_build_infra_common.sh
. "${BASH_SOURCE[0]%/*}/yb_build_infra_common.sh"

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
  --tag_prefix <prefix>
    If this is specified, prefix the tag with "<prefix>/". This is typically the username or the
    organization on Docker Hub.
  --tag_output_file <tag_output_file>
    The file to write the resulting Docker image tag to
  -p, --push
    Push the built image(s) to DockerHub (must be logged in).
  --is_pr <true|false>
    Specify whether this is a pull request.
  --github_org
    When running on CI/CD, the GitHub organization of the repository being tested, or the user
    submitting the pull request.
EOT
}

# http://bit.ly/print_usage_to
if [[ $# -eq 0 ]]; then
  print_usage >&2
  exit 1
fi

image_name=""
should_push=false
tag_prefix=""
tag_output_file=""
github_org=""
is_pr=false

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
    --tag_prefix)
      tag_prefix=$2
      shift
    ;;
    --tag_output_file)
      tag_output_file=$2
      shift
    ;;
    --github_org)
      github_org=$2
      shift
    ;;
    --is_pr)
      is_pr=$2
      if [[ ! $is_pr =~ ^(true|false) ]]; then
        echo "Invalid value of --is_pr: $is_pr (expected true/false)" >&2
        exit 1
      fi
      shift
    ;;
    *)
      print_usage >&2
      echo >&2
      fatal "Unknown option: $1"
  esac
  shift
done

dockerfile_path=$yb_build_infra_root/docker_images/$image_name/Dockerfile

timestamp=$( get_timestamp_for_filenames )

if [[ -z $tag_prefix && -n $github_org ]]; then
  if [[ $github_org == "yugabyte" ]]; then
    dockerhub_org="yugabyteci"
    dockerhub_user="yugabyteci"
  else
    dockerhub_org=$github_org
    dockerhub_user=$github_org
  fi
  log "Using DockerHub organization: $dockerhub_org"
  log "Using DockerHub user name: $dockerhub_user"
fi

if [[ $is_pr == "true" && $should_push == "true" ]]; then
  log "This is a pull request (--is_pr specified as true), will not push to DockerHub."
fi

if [[ -n $tag_prefix ]]; then
  tag_prefix=$tag_prefix/
fi

arch=$( uname -m )
tag=${tag_prefix}yb_build_infra_${image_name}_${arch}:v${timestamp}
if [[ -n $tag_output_file ]]; then
  echo "$tag" >"$tag_output_file"
fi

(
  set -x
  # We need to change to this directory to be able to reference scripts from docker_setup_scripts.
  cd "$yb_build_infra_root"

  docker build -f "$dockerfile_path" -t "$tag" .
)

if [[ $should_push == "true" ]]; then
  if [[ $is_pr == "true" ]]; then
    log "This is a pull request, not pushing to DockerHub"
  else
    if [[ -n ${DOCKERHUB_TOKEN:-} ]]; then
      log "Logging into DockerHub as user '$dockerhub_user'"
      echo "${DOCKERHUB_TOKEN}" | \
        docker login -u "$dockerhub_user" --password-stdin
    else
      log "DOCKERHUB_TOKEN is not set, not attempting to log into DockerHub"
    fi

    ( set -x; docker push "$tag" )
  fi
fi
