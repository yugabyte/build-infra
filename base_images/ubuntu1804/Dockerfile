FROM ubuntu:18.04

RUN apt-get update && \
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
      uuid-dev && \
    apt-get -y clean && \
    apt-get -y autoremove
