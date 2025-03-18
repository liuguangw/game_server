FROM golang:1.23-alpine AS builder
# alpine源镜像地址
ARG ALPINE_MIRROR_URL=""
# git url
ARG BILL_GIT_URL="https://github.com/liuguangw/billing_go.git"
# go proxy
ARG GOPROXY=""
ENV GOPROXY=$GOPROXY
RUN set -eux; \
	if [ ! -z "$ALPINE_MIRROR_URL" ];then \
		sed -i "s/dl-cdn.alpinelinux.org/$ALPINE_MIRROR_URL/g" /etc/apk/repositories; \
	fi \
	&& apk update \
	&& apk add git make \
	&& cd /home \
	&& git clone $BILL_GIT_URL billing_go \
	&& cd billing_go \
	&& make x64

FROM debian:buster-slim
# Debian源镜像地址
ARG DEBIAN_MIRROR_URL=""
WORKDIR /home
COPY files /root/
ADD lib/mysql-connector-odbc-5.3.13-linux-glibc2.12-x86-32bit.tar.gz /root/
COPY --from=builder /home/billing_go/billing-release-x64.tar.gz /root/
RUN set -eux; \
	if [ ! -z "$DEBIAN_MIRROR_URL" ];then \
		sed -i "s/deb.debian.org/$DEBIAN_MIRROR_URL/g" /etc/apt/sources.list; \
	fi \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends libc6:i386 libstdc++6:i386 unixodbc:i386 zlib1g:i386 tzdata procps \
	&& rm -rf /var/lib/apt/lists/* \
	&& cd /root \
	&& chmod +x ./shells/*.sh \
	&& ln -s /root/shells/run.sh /usr/local/bin/run_gs \
	&& ln -s /root/shells/stop.sh /usr/local/bin/stop_gs \
	&& tar -zxf billing-release-x64.tar.gz \
	&& mv billing-release-x64 billing_server \
	&& rm billing_server/*.exe \
	&& chmod +x ./billing_server/billing \
	&& cd mysql-connector-odbc-5.3.13-linux-glibc2.12-x86-32bit \
	&& mv bin/* /usr/local/bin/ \
	&& mv lib/* /usr/local/lib/ \
	&& cd .. \
	&& rm -rf ./*.gz \
	&& rm -rf ./mysql* \
	&& ldconfig \
	&& myodbc-installer -a -d -n "MySQL ODBC 5.3 Driver" -t "Driver=/usr/local/lib/libmyodbc5w.so" \
	&& myodbc-installer -d -l
HEALTHCHECK CMD pgrep -f "./billing" && pgrep -f "./ShareMemory" \
	&& pgrep -f "./World" && pgrep -f "./Login" \
	&& pgrep -f "./Server"
EXPOSE 7384 3731
CMD ["run_gs"]
