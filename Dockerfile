FROM centos:6

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV WAARP_R66_VERSION=3.0.7
ENV WAARP_PASSWORD_VERSION=3.0.2

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


# Download Waarp rpm package 3.0.6
RUN curl https://dl.waarp.org/repos/rhel6/waarp-ctl-0.1.2-1.el6.x86_64.rpm -o /tmp/waarp-ctl.rpm
RUN rpm --force -iv /tmp/waarp-ctl.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-common-1.0.0-1.el6.noarch.rpm -o /tmp/waarp-common-1.rpm && \
	rpm --force -iv /tmp/waarp-common-1.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-common-3.0.7-1.el6.noarch.rpm -o /tmp/waarp-common.rpm && \
	rpm --force -iv /tmp/waarp-common.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-client-3.0.7-1.el6.noarch.rpm -o /tmp/waarp-r66-client.rpm && \
	rpm --force -iv /tmp/waarp-r66-client.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-server-3.0.7-1.el6.noarch.rpm -o /tmp/waarp-r66-server.rpm && \
	rpm --force -iv /tmp/waarp-r66-server.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-repo-1.0.0-1.el6.noarch.rpm -o /tmp/waarp-repo.rpm && \
	rpm --force -iv /tmp/waarp-repo.rpm

RUN rm -f /tmp/waarp*.rpm

ENV R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"

# Waarp binaries and configuration files
ADD assets/bin/ /usr/bin/
RUN chmod 755 \
	/usr/bin/waarp-r66server \
	/usr/bin/waarp-r66client

COPY assets/*.sh /usr/share/waarp/
RUN chmod 755 /usr/share/waarp/*.sh && \
	echo "export TERM=xterm-256color" >> ~/.bashrc && \
	echo ". /usr/share/waarp/init-commands.sh" >> ~/.bashrc

ADD assets/certs/* /etc/waarp/certs/
ADD assets/conf.d/ /tmp/conf.d/
COPY assets/init-functions /usr/share/waarp/

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh


# Waarp ports
EXPOSE 6666 6667

# HTTP Admin ports
EXPOSE 8066 8067

# REST API ports
EXPOSE 8088


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

