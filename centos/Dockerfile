FROM amd64/centos:6

LABEL maintainer="Florian JUDITH <florian.judith.b@gmail.com>"

ENV WAARP_R66_VERSION=3.0.10

RUN yum update -y
RUN yum install -y epel-release
RUN yum install -y \
		unzip \
		wget \
		libxslt \
		xmlstarlet \
		initscripts \
		java-1.8.0-openjdk

RUN yum clean all

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-${WAARP_R66_VERSION}-1.el6.noarch.rpm -o /tmp/waarp-r66.rpm && \
	ls -l /tmp && \
	rpm --force -iv /tmp/waarp-r66.rpm

RUN rm -f /tmp/waarp*.rpm

# Add JDBC drivers
RUN pushd /usr/share/waarp/r66-lib/ && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jre6.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jre7.jar && \
	curl -O https://jdbc.postgresql.org/download/postgresql-42.1.4.jar && \
	popd

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
 	/usr/bin/waarp-r66server \
 	/usr/bin/waarp-r66client \
 	/etc/waarp/ \
 	/usr/share/waarp/ \
 	/var/lib/waarp/

USER waarp

WORKDIR /usr/share/waarp

ENTRYPOINT ["/docker-entrypoint.sh"]

# CMD ["bash"]