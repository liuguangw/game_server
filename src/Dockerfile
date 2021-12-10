FROM debian:buster-slim
COPY config /root/config
COPY files /root/files
RUN cd /root/files \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends libc6:i386 libstdc++6:i386 unixodbc:i386 zlib1g:i386 ca-certificates wget tzdata mariadb-client procps \
	&& rm -rf /var/lib/apt/lists/* \
	&& chmod +x *.sh \
	&& ln -s /root/files/run.sh /usr/local/bin/run_gs \
	&& ln -s /root/files/stop.sh /usr/local/bin/stop_gs \
	&& wget https://github.com/liuguangw/billing_go/releases/download/v1.3.2/billing_1.3.2.tar.gz \
	&& tar -zxf billing_1.3.2.tar.gz \
	&& mv billing_1.3.2 billing_server \
	&& rm billing_server/*.exe \
	&& chmod a+x /root/files/billing_server/billing \
	&& tar -zxf mysql-connector-odbc-5.3.13-linux-glibc2.12-x86-32bit.tar.gz \
	&& cd mysql-connector-odbc-5.3.13-linux-glibc2.12-x86-32bit \
	&& cp bin/* /usr/local/bin \
	&& cp lib/* /usr/local/lib \
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
