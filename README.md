# YugabyteDB build infrastructure

![Docker](https://github.com/yugabyte/build-infra/workflows/Docker/badge.svg)

This repository contains code to build Docker images that can be used to build
YugabyteDB. On every commit to this repository we automatically build and push
the following Docker images:

- https://hub.docker.com/repository/docker/yugabyteci/yb_build_infra_centos7
- https://hub.docker.com/repository/docker/yugabyteci/yb_build_infra_ubuntu1804
