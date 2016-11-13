FROM fjudith/waarp-r66

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV WAARP_R66_VERSION=3.0.7
ENV WAARP_GWFTP_VERSION=3.0.4
ENV WAARP_PASSWORD_VERSION=3.0.2

RUN yum update -y
RUN yum install -y \
		lsof \
		supervisor

RUN yum clean all

# Download & deploy Waarp Gateway Ftp patch 3.0.4
RUN pushd /tmp/ && \
	curl -O https://dl.waarp.org/dist/waarp-gateway-ftp/3.0/waarp-gateway-ftp-${WAARP_GWFTP_VERSION}.zip && \
	unzip -x /tmp/waarp-gateway-ftp-${WAARP_GWFTP_VERSION}.zip -d /tmp/ && \
	cp -r /tmp/waarp-gateway-ftp-${WAARP_GWFTP_VERSION}/admin/* /usr/share/waarp/gwftp-admin/ && \
	rm -rf /tmp/waarp-gateway-ftp-${WAARP_GWFTP_VERSION} && \
	popd

# Duplicate Waarp library
RUN mkdir -p /usr/share/waarp/gwftp && \
	cp -av /usr/share/waarp/r66-lib/* /usr/share/waarp/gwftp-lib/

# Cleanup
RUN pushd /usr/share/waarp/gwftp-lib/ && rm -f \
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
    WaarpAdministrator-3.0.0.jar WaarpCommon-3.0.4.jar WaarpGatewayFtp-3.0.2.jar \
    WaarpCommon-3.0.6.jar WaarpDigest-3.0.0.jar \
    WaarpExec-3.0.0.jar WaarpFtp-Core-3.0.2.jar \
    WaarpFtp-Filesystem-3.0.2.jar WaarpGatewayKernel-3.0.3.jar \
    WaarpGatewayKernel-3.0.5.jar WaarpPassword-3.0.1.jar \
    WaarpProxyR66-3.0.1.jar WaarpR66-3.0.4.jar WaarpR66-3.0.6.jar \
    WaarpR66Gui-3.0.0.jar WaarpSnmp-3.0.0.jar WaarpThrift-3.0.0.jar \
    xml-apis-1.0.b2.jar xml-apis.jar XMLEditor-2.2.jar xmleditor.jar && \
    popd

# Waarp Internal Name
ENV WAARP_APPNAME="gwftp1"
ENV WAARP_DATABASE_LANGUAGE="en"
ENV WAARP_ADMIN_PASSWORD="password"

# Waarp Ftp CLient
ENV WAARP_FTPCLIENT_USER="ftp-client"
ENV WAARP_FTPCLIENT_PASSWORD="password"
ENV WAARP_FTPCLIENT_RETREIVECMD="NONE"
ENV WAARP_FTPCLIENT_STORECMD="NONE"

# Waarp Database configuration
ENV WAARP_DATABASE_TYPE="h2"
ENV WAARP_DATABASE_NAME="${WAARP_APPNAME}_waarp"
ENV WAARP_DATABASE_USER="gwftp"
ENV WAARP_DATABASE_PASSWORD="gwftp"
ENV WAARP_DATABASE_URL="jdbc:${WAARP_DATABASE_TYPE}:/var/lib/waarp/${WAARP_APPNAME}/db/${WAARP_DATABASE_NAME};MODE=ORACLE;AUTO_SERVER=TRUE"

# SSL
ENV WAARP_SSL_DNAME="CN=${WAARP_APPNAME}, OU=xfer, O=MyCompany, L=Paris, S=Paris, C=FR"
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

# Waarp binaries and configuration files
ADD assets/bin/ /usr/bin/
ADD assets/certs/* /etc/waarp/certs/
ADD assets/conf.d/ /etc/waarp/conf.d/

# Waarp log
ENV GWFTP_CLASSPATH="/usr/share/waarp/gwftp-lib/WaarpGatewayFtp-${WAARP_GWFTP_VERSION}.jar:/usr/share/waarp/gwftp-lib/*"
ENV SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/gwftp.xml"
ENV CLIENT_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/client.xml"
ENV LOGSERVER=" -Dlogback.configurationFile=/etc/waarp/conf.d/${WAARP_APPNAME}/logback-gwftp.xml "
ENV LOGCLIENT=" -Dlogback.configurationFile=/etc/waarp/conf.d/${WAARP_APPNAME}/logback-client.xml "

COPY supervisord.conf /etc/supervisord.conf
COPY assets/init-functions /usr/share/waarp/
COPY assets/*.sh /usr/share/waarp/
RUN chmod +x /usr/share/waarp/* && \
	. /usr/share/waarp/init-commands.sh

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
RUN mkdir -p /var/lib/waarp/gwftp/ftp

# GwFTP ports
EXPOSE 6621

# HTTP Admin ports
EXPOSE 8076 8077

# GwFTP PASV ports
EXPOSE 50001-65534

WORKDIR /usr/share/waarp

ENTRYPOINT ["/docker-entrypoint.sh"]
# ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]