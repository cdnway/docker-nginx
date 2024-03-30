# Nginx Dockerfile

FROM almalinux:9-minimal

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

RUN dnf config-manager --set-enabled crb

RUN echo ${PCRE_VER}

