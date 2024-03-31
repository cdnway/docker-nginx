# Nginx Dockerfile

FROM almalinux:latest

LABEL maintainer="wanyi <root@wanyigroup.com>"

# 定义版本变量
ENV JEMALLOC_VER=5.3.0 \
    LUAJIT_VER=2.1-20231117 \
    MAXMIND_VER=1.9.1 \
    NGINX_VER=1.25.4 \
    OPENSSL_VER=3.2.1 \
    PCRE_VER=8.45 \
    PCRE2_VER=10.43 \
    ZLIB_VER=1.3.1 \
    RESTY_DEST=/usr/local/share/luajit-2.1.0/resty

#SHELL ["/bin/bash", "-c"]

RUN yum -y update && \
    yum -y install dnf

RUN yum -y install dnf-plugins-core \
  && yum install --assumeyes epel-release 

RUN yum install -y wget curl tar screen curl python3 mlocate git gcc gcc-c++ make automake autoconf libtool --allowerasing && \
    yum install -y pcre pcre-devel zlib zlib-devel openssl-devel vim python3 zip tar unzip bzip2 bzip2-devel expat-devel libuuid-devel gd gd-devel gettext-devel mhash.x86_64 libcurl-devel --allowerasing && \
    yum install -y libxslt-devel bison patch cmake xz ssdeep ssdeep-devel yajl libunwind libunwind-devel iftop net-tools rsync perl perl-FindBin perl-IPC-Cmd --allowerasing

# 设置工作目录
WORKDIR /usr/local/cdnway/src

# 下载、编译并安装 brotli
RUN git clone --depth 1 -b master --single-branch https://github.com/google/brotli.git \
    && cd brotli \
    && ./configure-cmake --disable-debug \
    && make \
    && make install

