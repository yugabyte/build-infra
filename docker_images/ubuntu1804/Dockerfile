FROM ubuntu:18.04

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
      apt-file \
      apt-utils \
      automake \
      bison \
      cmake \
      curl \
      flex \
      git \
      golang \
      less \
      libbz2-dev \
      libicu-dev \
      libreadline-dev \
      libssl-dev \
      libtool \
      maven \
      ninja-build \
      openjdk-8-jdk-headless \
      pkg-config \
      python-dev \
      python-pip \
      rsync \
      sudo \
      unzip \
      uuid-dev \
      wget \
      locales \
      python3-venv \
      python3-pip \
      vim \
      xz-utils \
      && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    adduser --disabled-password --gecos "" yugabyte-ci && \
    locale-gen en_US.UTF-8

COPY docker_setup_scripts /tmp/yb_docker_setup_scripts

RUN /tmp/yb_docker_setup_scripts/perform_common_setup.sh

RUN rm -rf /tmp/yb_docker_setup_scripts
