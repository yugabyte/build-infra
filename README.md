# YugabyteDB build infrastructure

[![Docker](https://github.com/yugabyte/build-infra/workflows/Docker/badge.svg)](https://github.com/yugabyte/build-infra/actions?query=workflow%3ADocker)

This repository contains code to build Docker images that can be used to build
YugabyteDB. On every commit to this repository we automatically build and push
the following Docker images for x86_64.

## x86_64 images

The following x86_64 Docker images get built by GitHub Actions automation:

- AlmaLinux 8: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux8_x86_64/tags
- AlmaLinux 9: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux9_x86_64/tags
- Amazon Linux 2: https://hub.docker.com/r/yugabyteci/yb_build_infra_amazonlinux2_x86_64/tags
- CentOS 7: https://hub.docker.com/r/yugabyteci/yb_build_infra_centos7_x86_64/tags
- Ubuntu 18.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu1804_x86_64/tags
- Ubuntu 20.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2004_x86_64/tags
- Ubuntu 22.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2204_x86_64/tags
- Ubuntu 23.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2304_x86_64/tags

## aarch64 images

The following aarch64 Docker images get built by CircleCI automation:

- CentOS 7: https://hub.docker.com/r/yugabyteci/yb_build_infra_centos7_aarch64/tags
- AlmaLinux 8: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux8_aarch64/tags
- AlmaLinux 9: https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux9_aarch64/tags
- Amazon Linux 2: https://hub.docker.com/r/yugabyteci/yb_build_infra_amazonlinux2_aarch64/tags
- Ubuntu 20.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2004_aarch64/tags
- Ubuntu 22.04: https://hub.docker.com/r/yugabyteci/yb_build_infra_ubuntu2204_aarch64/tags

## Using these images to build yugabyte-db

The GitHub Actions workflow in the yugabyte-db repo ( https://github.com/yugabyte/yugabyte-db/blob/master/.github/workflows/build.yml ) uses images built using this repository to build YugabyteDB code. A simplified manual version of this workflow could be as follows.

```bash
docker run -it --cap-add=SYS_PTRACE yugabyteci/yb_build_infra_almalinux8_x86_64:v2022-10-13T18_10_49`
```
Note: the particular image used above is just an example. Grab the most recent AlmaLinux 8 x86_64 image from https://hub.docker.com/r/yugabyteci/yb_build_infra_almalinux8_x86_64/tags instead.

Now you can build e.g. the ASAN (AddressSanitizer) build type of YugabyteDB as follows. The `--cap-add=SYS_PTRACE` capability we have added is necessary for the ASAN build.
```
[root@9260ed49ae6b /]# sudo su - yugabyteci
[yugabyteci@9260ed49ae6b ~]$ git clone https://github.com/yugabyte/yugabyte-db
Cloning into 'yugabyte-db'...
remote: Enumerating objects: 415986, done.
remote: Counting objects: 100% (1652/1652), done.
remote: Compressing objects: 100% (888/888), done.
remote: Total 415986 (delta 949), reused 1200 (delta 717), pack-reused 414334
Receiving objects: 100% (415986/415986), 489.97 MiB | 31.08 MiB/s, done.
Resolving deltas: 100% (303630/303630), done.
Updating files: 100% (22067/22067), done.
[yugabyteci@9260ed49ae6b ~]$ cd yugabyte-db
[yugabyteci@9260ed49ae6b yugabyte-db]$ ./yb_build.sh asan
```

