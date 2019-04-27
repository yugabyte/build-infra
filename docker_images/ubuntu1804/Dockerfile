FROM ubuntu:18.04

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
      bison \
      cmake \
      flex \
      libbz2-dev \
      libreadline-dev \
      maven \
      ninja-build \
      openjdk-8-jdk-headless \
      python-dev \
      python-pip \
      rsync \
      sudo \
      git \
      less \
      apt-utils \
      curl \
      wget \
      unzip \
      automake \
      libtool \
      apt-file \
      uuid-dev \
      pkg-config \
      && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    adduser --disabled-password --gecos "" yugabuilder
