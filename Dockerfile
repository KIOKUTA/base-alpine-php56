# 基于alpine的php5.6版本需要使用alpine3.8基础镜像
#FROM alpine:3.8
FROM php:5.6.40-cli-alpine3.8

LABEL maintainer="stephen@iot-sw.net" \
      license="MIT" \
      org.label-schema.schema-version="1.0.0" \
      org.label-schema.vendor="KIOKUTA" \
      org.label-schema.name="alpine-php56-cli-gearman" \
      org.label-schema.description="small php56 with gearman extension image based on alpine" \
      org.label-schema.vcs-url="https://github.com/KIOKUTA/base-alpine-php56"

WORKDIR /data/worker

ENV TIMEZONE Asia/Shanghai

# 单元测试工具
COPY ./Extension/phar/phpunit-5.7.phar /usr/bin/phpunit

# 代码规范检查工具
COPY ./Extension/phar/phpcs-3.4.2.phar /usr/bin/phpcs

# 自动化代码修正工具
COPY ./Extension/phar/phpcbf-3.4.2.phar /usr/bin/phpcbf

# 添加gearman扩展
COPY ./Extension/gearman/gearmand-1.1.17.tar.gz /tmp/
COPY ./Extension/gearman/patches/libhashkit-common.h.patch /tmp/
COPY ./Extension/gearman/patches/libtest-cmdline.cc.patch /tmp/

# 添加对应的应用
RUN apk update \
    && apk add --no-cache --virtual .build-deps \
        wget \
        tar \
        ca-certificates \
        file \
        alpine-sdk \
        gperf \
        boost-dev \
        libevent-dev \
        util-linux-dev \
        hiredis-dev \
        yaml-dev \
        libressl-dev \
        autoconf \
        re2c \
        tzdata \
        make \
        boost-program_options \
        libevent \
        libuuid \
        libstdc++ \
        && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
        && echo "${TIMEZONE}" > /etc/timezone \
        && apk del tzdata \
        && mkdir -p /data/worker /data/log \
        && printf "\n" | pecl install redis-4.3.0 \
        && docker-php-ext-enable redis \
        && pecl install yaml-1.3.2 \
        && docker-php-ext-enable yaml \
        && cd /tmp \
        && tar xfz gearmand-1.1.17.tar.gz \
        && cd gearmand-1.1.17 \
        && patch -p1 < /tmp/libhashkit-common.h.patch \
        && patch -p1 < /tmp/libtest-cmdline.cc.patch \
        && ./configure \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --with-mysql=no \
            --with-postgresql=no \
            --disable-libpq \
            --disable-libtokyocabinet \
            --disable-libdrizzle \
            --disable-libmemcached \
            --enable-ssl \
            --disable-hiredis \
            --enable-jobserver=no \
        && make \
        && make install \
        && cd /tmp \
        && rm -rf gearmand-1.1.17.tar.gz \
        && rm -rf libhashkit-common.h.patch \
        && rm -rf libtest-cmdline.cc.patch \
        && rm -rf gearmand-1.1.17 \
        && pecl install gearman-1.1.2 \
        && docker-php-ext-enable gearman \
        && rm -rf /tmp/pear/download/* \
        && apk del .build-deps

# 添加缺失的动态库
RUN apk add --no-cache boost-program_options \
        libevent \
        libuuid \
        libstdc++ \
        yaml \
        make
        
VOLUME ["/data/worker", "/data/log"]



