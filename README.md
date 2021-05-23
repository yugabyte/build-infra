# YugabyteDB build infrastructure

[![Docker](https://github.com/yugabyte/build-infra/workflows/Docker/badge.svg)](https://github.com/yugabyte/build-infra/actions?query=workflow%3ADocker)


This repository contains code to build Docker images that can be used to build
YugabyteDB. On every commit to this repository we automatically build and push
the following Docker images:

- CentOS 7: https://hub.docker.com/r/yugabyteci/yb_build_infra_centos7/tags
- CentOS 8: https://hub.docker.com/r/yugabyteci/yb_build_infra_centos8/tags
- Ubuntu 18.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu1804/tags
- Ubuntu 20.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2004/tags
