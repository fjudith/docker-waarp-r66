#!/bin/sh
# set -e

export JAVAEXECCLIENT="java -cp ${GWFTP_CLASSPATH} ${LOGCLIENT} -Dfile.encoding=UTF-8 "
export JAVAEXECSERVER="java -cp ${GWFTP_CLASSPATH} ${LOGSERVER} -Dfile.encoding=UTF-8 "

export SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/gwftp.xml"
export CLIENT_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/client.xml"
export R66CONF="/etc/waarp/conf.d/${R66_ENV_WAARP_APPNAME}/server.xml"

##################
# GwFTP COMMANDS #
##################

# SERVER SIDE #
###############
# start the GwFTP server
# no option
export GWFTPSERVER="/usr/bin/waarp-gwftp"
alias gwftpserver="${GWFTPSERVER} ${WAARP_APPNAME} start "

# init database from argument
# [ -initdb ]
export GWFTPINIT="${JAVAEXECCLIENT} org.waarp.gateway.ftp.ServerInitDatabase ${SERVER_CONFIG} "
alias gwftpinit="${GWFTPINIT}"

# shutdown by network the server
# [-nossl|-ssl] default = -ssl
export GWFTPSHUTD="${JAVAEXECCLIENT} org.waarp.gateway.ftp.ServerShutdown ${SERVER_CONFIG} "
alias gwftpshutd="${GWFTPSHUTD}"

# export the log
# [ -purge ] [ -clean ] [ -start timestamp ] [ -stop timestamp ] where timestamp are in yyyyMMddHHmmssSSS format eventually truncated and with possible ':- ' as separators
export GWFTPLOGEXPORT="${JAVAEXECCLIENT} org.waarp.gateway.ftp.LogExport ${SERVER_CONFIG} "
alias gwftpexport="${GWFTPEXPORT}"
