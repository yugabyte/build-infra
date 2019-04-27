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

# https://askubuntu.com/questions/94060/run-adduser-non-interactively
RUN adduser --disabled-password --gecos "" yugabuilder
