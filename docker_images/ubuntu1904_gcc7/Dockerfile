FROM ubuntu:19.04

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
      libffi-dev \
      && \
    apt-get remove -y gcc-8 g++-8 && \
    apt-get install -y gcc-7 g++-7 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 90 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 90 && \
    update-alternatives --set gcc "/usr/bin/gcc-7" && \
    update-alternatives --set g++ "/usr/bin/g++-7" && \
    which gcc && \
    which g++ && \
    apt-get -y clean && \
    apt-get -y autoremove && \
    adduser --disabled-password --gecos "" yugabuilder

COPY docker_setup_scripts/install_hub_tool.sh /tmp/install_hub_tool.sh

RUN bash /tmp/install_hub_tool.sh && rm -f /tmp/install_hub_tool.sh
