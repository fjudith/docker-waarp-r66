FROM centos:6

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV WAARP_R66_VERSION=3.0.7
ENV WAARP_GWFTP_VERSION=3.0.4
ENV WAARP_PASSWORD_VERSION=3.0.2

ENV R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"
ENV FTP_CLASSPATH="/usr/share/waarp/gwftp-lib/WaarpGatewayFtp-${WAARP_GWFTP_VERSION}.jar:/usr/share/waarp/gwftp-lib/*"
ENV SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/server.xml"
ENV CLIENT_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/client.xml"

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

# Download Waarp rpm package 3.0.4
RUN curl https://dl.waarp.org/repos/rhel6/waarp-ctl-0.1.1-1.el6.x86_64.rpm -o /tmp/waarp-ctl.rpm
RUN rpm -iv /tmp/waarp-ctl.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-common-1.0.0-1.el6.noarch.rpm -o /tmp/waarp-common-1.rpm && \
	rpm -iv /tmp/waarp-common-1.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-common-3.0.4-1.el6.noarch.rpm -o /tmp/waarp-common.rpm && \
	rpm -iv /tmp/waarp-common.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-client-3.0.4-3.el6.noarch.rpm -o /tmp/waarp-r66-client.rpm && \
	rpm -iv /tmp/waarp-r66-client.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-r66-server-3.0.4-2.el6.noarch.rpm -o /tmp/waarp-r66-server.rpm && \
	rpm -iv /tmp/waarp-r66-server.rpm

RUN curl https://dl.waarp.org/repos/rhel6/waarp-gateway-ftp-3.0.2-1.el6.noarch.rpm -o /tmp/waarp-gateway-ftp.rpm && \
	rpm -iv /tmp/waarp-gateway-ftp.rpm

RUN rm -f /tmp/waarp*.rpm

# Download & deploy Waarp Gateway Ftp patch 3.0.4
RUN pushd /tmp/ && \
	curl -O https://dl.waarp.org/dist/waarp-gateway-ftp/3.0/waarp-gateway-ftp-3.0.4.zip && \
	unzip -x /tmp/waarp-gateway-ftp-3.0.4.zip -d /tmp/ && \
	cp /tmp/waarp-gateway-ftp-3.0.4/lib/*.jar /usr/share/waarp/r66-lib/ && \
	cp /tmp/waarp-gateway-ftp-3.0.4/lib/*.jar /usr/share/waarp/gwftp-lib/ && \
	rm -rf /tmp/waarp-gateway-ftp-3.0.4 && \
	popd

# Download & deploy Waarp R66 patch 3.0.6-beta1
RUN pushd /tmp/ && \
	curl -O https://dl.waarp.org/dist/waarp-r66/3.0/waarp-r66-3.0.6.zip && \
	unzip -x /tmp/waarp-r66-3.0.6.zip -d /tmp/ && \
	cp /tmp/waarp-r66-3.0.6/lib/*.jar /usr/share/waarp/r66-lib/ && \
	cp /tmp/waarp-r66-3.0.6/lib/*.jar /usr/share/waarp/gwftp-lib/ && \
	rm -rf /tmp/waarp-r66-3.0.6 && \
	popd

# Download & deploy Waarp R66 patch 3.0.7-beta1
RUN pushd /tmp/ && \
	curl -O https://discuss.waarp.org/uploads/default/original/1X/ac660f17911ae8388aebb46f963cbdd90e2227f0.zip && \
	unzip -x /tmp/ac660f17911ae8388aebb46f963cbdd90e2227f0.zip -d /tmp/ && \
	cp /tmp/waarp-r66-3.0.7-beta1/lib/*.jar /usr/share/waarp/r66-lib/ && \
	cp /tmp/waarp-r66-3.0.7-beta1/lib/*.jar /usr/share/waarp/gwftp-lib/ && \
	rm -rf /tmp/waarp-r66-3.0.7-beta1 && \
	popd

# Cleanup
RUN pushd /usr/share/waarp/r66-lib/ && rm -f \
	commons-compress-1.10.jar commons-compress-1.9.jar \
	commons-io-2.4.jar commons-net-3.3-ftp.jar h2-1.3.176.jar \
	httpclient-4.2.5.jar httpcore-4.2.4.jar \
    jackson-annotations-2.5.3.jar jackson-annotations-2.7.1.jar \
    jackson-core-2.5.3.jar jackson-core-2.7.1.jar \
    jackson-databind-2.5.3.jar jackson-databind-2.7.1-1.jar \
    javassist-3.18.2-GA.jar \
    joda-time-2.7.jar joda-time-2.9.1.jar \
    libthrift-0.9.2.jar logback-classic-1.1.3.jar \
    logback-core-1.1.3.jar mariadb-java-client-1.1.8.jar \
    mariadb-java-client-1.3.4.jar mysql-connector-java-5.1.35.jar \
    mysql-connector-java-5.1.36.jar netty-all-4.1.0.Beta5.jar \
    netty-all-4.1.0.CR3.jar postgresql-9.4-1201-jdbc4.jar \
    postgresql-9.4-1206-jdbc4.jar slf4j-api-1.7.12.jar \
    snmp4j-2.3.1.jar snmp4j-agent-2.2.2.jar \
    WaarpAdministrator-3.0.0.jar WaarpCommon-3.0.4.jar \
    WaarpCommon-3.0.6.jar WaarpDigest-3.0.0.jar \
    WaarpExec-3.0.0.jar WaarpFtp-Core-3.0.2.jar \
    WaarpFtp-Filesystem-3.0.2.jar WaarpGatewayKernel-3.0.3.jar \
    WaarpGatewayKernel-3.0.5.jar WaarpPassword-3.0.1.jar \
    WaarpProxyR66-3.0.1.jar WaarpR66-3.0.4.jar WaarpR66-3.0.6.jar \
    WaarpR66Gui-3.0.0.jar WaarpSnmp-3.0.0.jar WaarpThrift-3.0.0.jar \
    xml-apis-1.0.b2.jar xml-apis.jar XMLEditor-2.2.jar xmleditor.jar && \
    popd

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


# Waarp binaries and configuration files
ADD assets/bin/ /usr/bin/
ADD assets/certs/* /etc/waarp/certs/
ADD assets/conf.d/ /etc/waarp/conf.d/

COPY assets/init-functions /usr/share/waarp/
COPY assets/*.sh /usr/share/waarp/
RUN chmod +x /usr/share/waarp/* && \
	/usr/share/waarp/init-commands.sh

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
CMD ["bash"]