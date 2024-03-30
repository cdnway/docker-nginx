# Nginx Dockerfile

FROM almalinux:9-minimal

LABEL maintainer="wanyi <root@wanyigroup.com>"

# 设置工作目录
WORKDIR /usr/local/cdnway/src

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

#RUN 'dnf config-manager --set-enabled crb'

RUN "dnf install -y epel-release"

RUN 'dnf install -y wget curl tar screen curl python3 mlocate git gcc gcc-c++ make automake autoconf libtool \
    pcre pcre-devel zlib zlib-devel openssl-devel vim python3 zip tar unzip bzip2 bzip2-devel expat-devel libuuid-devel gd gd-devel gettext-devel mhash.x86_64 libcurl-devel \
    libxslt-devel bison patch cmake xz ssdeep ssdeep-devel yajl libunwind libunwind-devel iftop net-tools rsync perl perl-FindBin perl-IPC-Cmd'

# 设置工作目录
WORKDIR /usr/local/cdnway/src

# 下载并安装jemalloc
RUN if [ -f "jemalloc-${JEMALLOC_VER}.tar.bz2" ]; then rm -rf jemalloc-${JEMALLOC_VER}.tar.bz2; fi \
    && wget -O jemalloc-${JEMALLOC_VER}.tar.bz2 https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VER}/jemalloc-${JEMALLOC_VER}.tar.bz2 \
    && if [ ! -d "jemalloc-${JEMALLOC_VER}" ]; then tar -xvf jemalloc-${JEMALLOC_VER}.tar.bz2; fi \
    && cd jemalloc-${JEMALLOC_VER} \
    && ./configure \
    && make \
    && make install \
    && ldconfig

# 下载并安装 LuaJIT
RUN wget https://github.com/openresty/luajit2/archive/v${LUAJIT_VER}.tar.gz \
    && tar xfvz v${LUAJIT_VER}.tar.gz \
    && cd luajit2-${LUAJIT_VER} \
    && make \
    && make install

# 克隆并复制 lua-resty-core 和 lua-resty-lrucache
RUN mkdir -p ${RESTY_DEST} \
    && git clone https://github.com/openresty/lua-resty-core \
    && git clone https://github.com/openresty/lua-resty-lrucache \
    && cp -Rp lua-resty-core/lib/resty/* ${RESTY_DEST}/ \
    && cp -Rp lua-resty-lrucache/lib/resty/* ${RESTY_DEST}/

# 下载并安装 libmaxminddb
RUN wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VER}/libmaxminddb-${MAXMIND_VER}.tar.gz \
    && tar xfz libmaxminddb-${MAXMIND_VER}.tar.gz \
    && cd libmaxminddb-${MAXMIND_VER} \
    && ./configure \
    && make \
    && make install \
    && ldconfig

# 下载、编译并安装 brotli
RUN git clone --depth 1 -b master --single-branch https://github.com/google/brotli.git \
    && cd brotli \
    && ./configure-cmake --disable-debug \
    && make \
    && make install

# 下载、编译并安装 sregex
RUN git clone https://github.com/openresty/sregex \
    && cd sregex \
    && make \
    && make install

# 克隆并安装 OpenSSL
RUN git clone https://github.com/quictls/openssl \
    && cd openssl \
    && ./Configure --prefix=/usr/local/quictls --openssldir=/usr/local/quictls \
    && make install_dev

# 设置工作目录
WORKDIR /usr/local/cdnway/src/nginx-${NGINX_VER}

# 下载并解压 nginx
RUN if [ ! -f "nginx-${NGINX_VER}.tar.gz" ]; then wget -4 http://nginx.org/download/nginx-${NGINX_VER}.tar.gz; fi \
    && if [ -d "nginx-${NGINX_VER}" ]; then rm -rf "nginx-${NGINX_VER}"; fi \
    && tar xfz nginx-${NGINX_VER}.tar.gz 

# 设置工作目录
WORKDIR /usr/local/cdnway/src/nginx-${NGINX_VER}/pkgmod
   
# 下载并解压pcre
RUN if [ ! -f "pcre-${PCRE_VER}.tar.gz" ]; then wget -4 https://phoenixnap.dl.sourceforge.net/project/pcre/pcre/${PCRE_VER}/pcre-${PCRE_VER}.tar.gz; fi \
    && tar xfz pcre-${PCRE_VER}.tar.gz

# 下载并解压pcre2
RUN if [ ! -f "pcre2-${PCRE2_VER}.tar.gz" ]; then wget -4 https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VER}/pcre2-${PCRE2_VER}.tar.gz; fi \
    && tar -zxf pcre2-${PCRE2_VER}.tar.gz

# 下载并解压zlib
RUN if [ ! -f "zlib-${ZLIB_VER}.tar.gz" ]; then wget -4 http://zlib.net/zlib-${ZLIB_VER}.tar.gz; fi \
    && tar -zxf zlib-${ZLIB_VER}.tar.gz \
    && wget http://zlib.net/current/zlib.tar.gz \
    && tar xfz zlib.tar.gz

# 克隆所需的nginx模块
# 子模块列表
ENV NGINX_MODULES="\
https://github.com/openresty/lua-nginx-module \
https://github.com/leev/ngx_http_geoip2_module \
https://github.com/simpl/ngx_devel_kit \
https://github.com/openresty/set-misc-nginx-module \
https://github.com/openresty/echo-nginx-module \
https://github.com/openresty/replace-filter-nginx-module \
https://github.com/openresty/headers-more-nginx-module \
https://github.com/calio/iconv-nginx-module \
https://github.com/FRiCKLE/ngx_cache_purge \
https://github.com/alibaba/nginx-http-footer-filter \
https://github.com/yaoweibin/ngx_http_substitutions_filter_module \
https://github.com/kaltura/nginx-vod-module \
https://github.com/kaltura/nginx-akamai-token-validate-module \
https://github.com/vozlt/nginx-module-vts \
https://github.com/google/ngx_brotli \
"

# 检查并克隆或更新模块
RUN for module in $NGINX_MODULES; do \
        module_name=$(basename $module); \
        module_dir=$(basename $module_name .git); \
        if [ ! -d "$module_dir" ]; then \
            git clone $module; \
        else \
            cd $module_dir || exit; \
            git submodule update --init --recursive; \
            cd ..; \
        fi \
    done

# 设置工作目录
WORKDIR /usr/local/cdnway/src/nginx-${NGINX_VER}

# 配置并构建 NGINX
RUN ./configure \
    --prefix=/usr/local/nginx \
    --add-module=pkgmod/ngx_http_geoip2_module \
    --add-module=pkgmod/ngx_devel_kit \
    --add-module=pkgmod/set-misc-nginx-module \
    --add-module=pkgmod/echo-nginx-module \
    --add-module=pkgmod/replace-filter-nginx-module \
    --add-module=pkgmod/headers-more-nginx-module \
    --add-module=pkgmod/iconv-nginx-module \
    --add-module=pkgmod/ngx_cache_purge \
    --add-module=pkgmod/nginx-http-footer-filter \
    --add-module=pkgmod/ngx_http_substitutions_filter_module \
    --add-module=pkgmod/lua-nginx-module \
    --add-module=pkgmod/nginx-vod-module \
    --add-module=pkgmod/nginx-akamai-token-validate-module \
    --add-module=pkgmod/nginx-module-vts \
    --with-pcre=pkgmod/pcre-${PCRE_VER} \
    --with-zlib=pkgmod/zlib-${ZLIB_VER} \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module \
    --with-http_secure_link_module \
    --with-http_image_filter_module \
    --with-http_gzip_static_module --with-http_gunzip_module \
    --with-file-aio --with-threads \
    --with-http_sub_module --with-http_stub_status_module \
    --with-http_flv_module --with-http_mp4_module --with-http_slice_module \
    --with-http_dav_module --with-http_addition_module \
    --with-http_realip_module \
    --with-cc-opt="-Wno-error -I /usr/local/quictls/include" \
    --with-ld-opt="-Wl,-E -ljemalloc -L /usr/local/quictls/lib64" \
    && make \
    && make install

RUN wget -O /etc/logrotate.d/nginx https://raw.githubusercontent.com/nginxplus/CDNToolkit/master/bin/nginx_logrotate

#ADD nginx-1.25.4.tar.gz /usr/local/src/ 
   
#ADD nginx.conf /apps/nginx/conf/nginx.conf

#COPY index.html /apps/nginx/html/

#RUN ln -s /apps/nginx/sbin/nginx /usr/sbin/nginx 

EXPOSE 80 443 7780

# 将 Entrypoint 脚本添加到容器中
COPY entrypoint.sh /entrypoint.sh

# 赋予 Entrypoint 脚本执行权限
RUN chmod +x /entrypoint.sh

# 设置 Entrypoint 脚本
ENTRYPOINT ["/entrypoint.sh"]
