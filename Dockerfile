FROM centos:6

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV WAARP_R66_VERSION=3.0.6
ENV WAARP_GWFTP_VERSION=3.0.4
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
RUN rpm -iv /tmp/waarp-ctl.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-common-1.0.0-1.el6.noarch.rpm -o /tmp/waarp-common-1.rpm && \
	rpm -iv /tmp/waarp-common-1.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-common-3.0.6-1.el6.noarch.rpm -o /tmp/waarp-common.rpm && \
	rpm -iv /tmp/waarp-common.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-client-3.0.6-1.el6.noarch.rpm -o /tmp/waarp-r66-client.rpm && \
	rpm -iv /tmp/waarp-r66-client.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-server-3.0.6-1.el6.noarch.rpm -o /tmp/waarp-r66-server.rpm && \
	rpm -iv /tmp/waarp-r66-server.rpm

RUN rm -f /tmp/waarp*.rpm

# Waap Internal Name
ENV WAARP_APPNAME="server1"
ENV WAARP_DATABASE_LANGUAGE="en"
ENV WAARP_ADMIN_PASSWORD="password"

# Waarp Database configuration
ENV WAARP_DATABASE_TYPE="h2"
ENV WAARP_DATABASE_NAME="${WAARP_APPNAME}_waarp"
ENV WAARP_DATABASE_USER="waarp"
ENV WAARP_DATABASE_PASSWORD="waarp"
ENV WAARP_DATABASE_URL="jdbc:${WAARP_DATABASE_TYPE}:/var/lib/waarp/${WAARP_APPNAME}/db/${WAARP_DATABASE_NAME};MODE=ORACLE;AUTO_SERVER=TRUE"

# SSL
ENV WAARP_SSL_DNAME="CN=${WAARP_APPNAME}\, OU=xfer\, O=MyCompany\, L=Paris\, S=Paris\, C=FR"
ENV WAARP_KEYSIZE="2048"
ENV WAARP_KEYALG="RSA"
ENV WAARP_SIGALG="SHA256withRSA"
ENV WAARP_KEYVAL="3650"
ENV WAARP_ADMKEYSTOREPASS="password"
ENV WAARP_ADMKEYPASS="password"
ENV WAARP_KEYSTOREPASS="password"
ENV WAARP_KEYPASS="password"
ENV WAARP_TRUSTKEYSTOREPASS="password"

# SNMP
ENV WAARP_SNMP_AUTHPASS="password"
ENV WAARP_SNMP_PRIVPASS="password"

ENV R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"
ENV SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/server.xml"
ENV CLIENT_CONFIG=${SERVER_CONFIG}
ENV LOGSERVER=" -Dlogback.configurationFile=/etc/waarp/conf.d/${WAARP_APPNAME}/logback-server.xml "
ENV LOGSERVER=" -Dlogback.configurationFile=/etc/waarp/conf.d/${WAARP_APPNAME}/logback-client.xml "

# Waarp binaries and configuration files
ADD assets/bin/ /usr/bin/
ADD assets/certs/* /etc/waarp/certs/
ADD assets/conf.d/ /etc/waarp/conf.d/

COPY assets/init-functions /usr/share/waarp/
COPY assets/*.sh /usr/share/waarp/
RUN chmod +x /usr/share/waarp/* && \
	echo "export TERM=xterm-256color" >> ~/.bashrc && \
	echo ". /usr/share/waarp/init-commands.sh" >> ~/.bashrc

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Waarp ports
EXPOSE 6666 6667

# HTTP Admin ports
EXPOSE 8066 8067

# REST API ports
EXPOSE 8088

WORKDIR /usr/share/waarp

ENTRYPOINT ["/docker-entrypoint.sh"]