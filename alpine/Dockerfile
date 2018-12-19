FROM amd64/openjdk:8-jdk-alpine

LABEL maintainer="Florian JUDITH <florian.judith.b@gmail.com>"

ENV WAARP_R66_VERSION=3.0.10

RUN apk add wget xmlstarlet libxslt

# Create waarp user
RUN addgroup -g 499 waarp && \
    adduser -s /bin/sh -G waarp -u 499 waarp

# Install Waarp Web administration UI
RUN mkdir -p \
    /etc/waarp \
    /usr/share/waarp \
    /var/lib/waarp

RUN cd /tmp/ && \
	curl -L https://dl.waarp.org/dist/waarp-r66/3.0/waarp-r66-${WAARP_R66_VERSION}-1.linux.tar.gz | tar xvzf - && \
	cp -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1/etc/* /etc/waarp/ && \
    cp -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1/share/* /usr/share/waarp/ && \
    cp -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1/bin/* /usr/bin/ && \
	rm -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1 && \
	cd /

# Add JDBC drivers
RUN cd /usr/share/waarp/r66-lib/ && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.0.0.jre6.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.0.0.jre7.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.0.0.jar && \
	cd /

ENV R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"

# Waarp configuration templatesls
COPY assets/*.sh /usr/share/waarp/
RUN chmod 755 /usr/share/waarp/*.sh && \
	echo "export TERM=xterm-256color" >> ~/.bashrc && \
	echo ". /usr/share/waarp/init-commands.sh" >> ~/.bashrc

ADD assets/certs/* /etc/waarp/certs/
ADD assets/conf.d/ /tmp/conf.d/

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Waarp ports
EXPOSE 6666 6667

# HTTP Admin ports
EXPOSE 8066 8067

# REST API ports
EXPOSE 8088

# Create spool and flags directories and apply permission to waarp user
RUN chown -R waarp:waarp \
 	/usr/bin/manager-send.sh \
    /usr/bin/variables.sh \
    /usr/bin/waarp-password.sh \
    /usr/bin/waarp-pull.sh \
    /usr/bin/waarp-r66server.sh \
 	/usr/bin/waarp-r66client.sh \
 	/etc/waarp/ \
 	/usr/share/waarp/ \
 	/var/lib/waarp/

USER waarp

WORKDIR /usr/share/waarp

ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD ["bash"]