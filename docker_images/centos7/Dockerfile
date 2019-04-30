FROM centos:7.6.1810

RUN yum upgrade -y && \
    yum install epel-release && \
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
      less \
      bind-utils \
      && \
    mkdir -p /usr/local/bin && \
    ln -s /usr/bin/cmake3 /usr/local/bin/cmake && \
    ln -s /usr/bin/ctest3 /usr/local/bin/ctest

RUN pip install --upgrade pip

