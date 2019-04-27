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

RUN apt-get install -y sudo
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get install -y git less
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get install -y apt-utils
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get install -y curl
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get install -y unzip
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get install -y automake apt-file
RUN apt-get -y clean && apt-get -y autoremove

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get -y clean && apt-get -y autoremove

RUN adduser --disabled-password --gecos "" yugabuilder
