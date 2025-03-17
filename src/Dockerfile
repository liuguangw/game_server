FROM golang:1.23-alpine AS builder
RUN set -eux \
    && apk add git make \
	&& cd /home \
	&& git clone https://github.com/liuguangw/billing_go.git \
	&& cd billing_go \
	&& make x64 \
	&& ls -al .

FROM debian:buster-slim
ARG APT_MIRROR_URL=""
WORKDIR /home
COPY files /root/
ADD lib/mysql-connector-odbc-5.3.13-linux-glibc2.12-x86-32bit.tar.gz /root/
COPY --from=builder /home/billing_go/billing-release-x64.tar.gz /root/
RUN set -eux; \
    if [ ! -z "$APT_MIRROR_URL" ];then \
	  sed -i "s/deb.debian.org/$APT_MIRROR_URL/g" /etc/apt/sources.list; \
    fi; \
	dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends libc6:i386 libstdc++6:i386 unixodbc:i386 zlib1g:i386 ca-certificates wget tzdata mariadb-client procps \
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
