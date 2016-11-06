JAVA_HOME=$(readlink -f $(dirname $(readlink -f $(which java)))/..)
JAVA_OPTS1="-server"
JAVA_OPTS2="-Xms256m -Xmx512m"
JAVA_RUN="${JAVA_HOME}/bin/java"

PATH=${JAVA_HOME}/bin:$PATH

#find first instance
if [[ -z $R66_INST ]]; then
    for inst in $(ls /etc/waarp/conf.d); do
        if [[ -e "/etc/waarp/conf.d/$inst/$R66_TYPE.xml" ]]; then
            export R66_INST=$inst
            break
        fi
    done
else
    if [[ ! -e "/etc/waarp/conf.d/$R66_INST/$R66_TYPE.xml" ]]; then
        echo "L'instance Waarp R66 $R66_INST n'existe pas"
        exit 2
    fi
fi

CONFDIR=${CONFDIR:-/etc/waarp/conf.d/$R66_INST}
PIDFILE=/var/lib/waarp/$R66_INST/r66server.pid
FTPPIDFILE=/var/lib/waarp/$R66_INST/gwftp.pid

LOGSERVER=" -Dlogback.configurationFile=${CONFDIR}/logback-server.xml "
LOGCLIENT=" -Dlogback.configurationFile=${CONFDIR}/logback-client.xml "
LOGGWFTP=" -Dlogback.configurationFile=${CONFDIR}/logback-gwftp.xml "

R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-3.0.7.jar:/usr/share/waarp/r66-lib/*"
FTP_CLASSPATH="/usr/share/waarp/gwftp-lib/WaarpGatewayFtp-3.0.4.jar:/usr/share/waarp/gwftp-lib/*"

JAVARUNCLIENT="${JAVA_RUN} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGCLIENT} "
JAVARUNSERVER="${JAVA_RUN} ${JAVA_OPTS1} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGSERVER} "
JAVARUNFTPSERVER="${JAVA_RUN} ${JAVA_OPTS1} ${JAVA_OPTS2} -cp ${FTP_CLASSPATH} ${LOGGWFTP} "