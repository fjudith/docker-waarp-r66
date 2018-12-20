FROM amd64/openjdk:8-jdk-alpine

LABEL maintainer="Florian JUDITH <florian.judith.b@gmail.com>"

ENV WAARP_R66_VERSION=3.0.10

RUN apk add bash tree curl wget xmlstarlet libxslt

# Create waarp user
RUN addgroup -g 499 waarp && \
    adduser -s /bin/sh -G waarp -u 499 waarp -D

# Install Waarp Web administration UI
RUN mkdir -p \
    /usr/share/waarp/etc/certs \
    /usr/share/waarp/etc/conf.d \
    /var/lib/waarp \
    /var/log/waarp

RUN cd /tmp/ && \
	curl -L https://dl.waarp.org/dist/waarp-r66/3.0/waarp-r66-${WAARP_R66_VERSION}-1.linux.tar.gz | tar xvzf - && \
	cp -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1/bin /usr/share/waarp/ && \
    cp -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1/share /usr/share/waarp/ && \
	rm -rf /tmp/waarp-r66-${WAARP_R66_VERSION}-1 && \
	cd /

# Add JDBC drivers
RUN cd /usr/share/waarp/share/lib/ && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jre6.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jre7.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jar && \
	cd /

ENV R66_CLASSPATH="/usr/share/waarp/share/lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/share/lib/*"

# Waarp configuration templatesls
RUN echo "export TERM=xterm-256color" >> ~/.bashrc && \
	echo ". /usr/share/waarp/init-commands.sh" >> ~/.bashrc

ADD assets/certs/* /usr/share/waarp/etc/certs/
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
 	/usr/share/waarp/ \
 	/var/lib/waarp/ \
    /var/log/waarp/

USER waarp

WORKDIR /usr/share/waarp

ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD ["bash"]