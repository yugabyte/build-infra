# YugabyteDB build infrastructure

[![Docker](https://github.com/yugabyte/build-infra/workflows/Docker/badge.svg)](https://github.com/yugabyte/build-infra/actions?query=workflow%3ADocker)


This repository contains code to build Docker images that can be used to build
YugabyteDB. On every commit to this repository we automatically build and push
the following Docker images for x86_64.

## x86_64 images

- AlmaLinux 8: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux8/tags
- CentOS 7: https://hub.docker.com/r/yugabyteci/yb_build_infra_centos7/tags
- Ubuntu 18.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu1804/tags
- Ubuntu 20.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2004/tags
- Ubuntu 22.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2204/tags

## aarch64 images

Also, the following aarch64 images have been built manually.

- AlmaLinux 8: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux8_aarch64/tags
- Ubuntu 20.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2004_aarch64/tags
- Ubuntu 22.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2204_aarch64/tags
