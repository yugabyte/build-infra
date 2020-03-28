FROM centos:7.6.1810

RUN yum upgrade -y && \
    yum install -y epel-release && \
    yum groupinstall -y 'Development Tools' && \
    yum install -y \
      autoconf \
      bind-utils \
      bzip2 \
      ccache \
      cmake3 \
      ctest3 \
      curl \
      epel-release \
      gcc \
      gcc-c++ \
      git \
      less \
      libffi-devel \
      libselinux-python \
      libsemanage-python \
      libtool \
      openssl-devel \
      patch \
      perl-Digest \
      php \
      php-common \
      php-curl \
      python2-pip \
      python-devel \
      ruby \
      ruby-devel \
      sudo \
      wget \
      which \
      readline-devel \
      bzip2-devel \
      gdbm-devel \
      libsqlite3x-devel \
      openssl-devel \
      centos-release-scl \
      devtoolset-8 \
      vim \
      xz \
      java-1.8.0-openjdk

RUN mkdir -p /usr/local/bin && \
    ln -s /usr/bin/cmake3 /usr/local/bin/cmake && \
    ln -s /usr/bin/ctest3 /usr/local/bin/ctest && \
    pip install --upgrade pip

RUN rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO && \
    curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo && \
    yum install -y golang

RUN adduser yugabyteci

RUN /tmp/yb_docker_setup_scripts/centos_install_python3_from_source.sh

RUN /tmp/yb_docker_setup_scripts/install_common_tools.sh