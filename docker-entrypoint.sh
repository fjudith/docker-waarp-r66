#! /bin/bash
set -e

export JAVA_HOME=$(readlink -f $(dirname $(readlink -f $(which java)))/..)
export JAVA_OPTS1="-server"
export JAVA_OPTS2="-Xms256m -Xmx512m"
export JAVA_RUN="${JAVA_HOME}/bin/java"

export PATH=${JAVA_HOME}/bin:$PATH

export CONFDIR=${CONFDIR:-/etc/waarp/conf.d/$WAARP_APPNAME}
export PIDFILE=/var/lib/waarp/${WAARP_APPNAME}/r66server.pid
export FTPPIDFILE=/var/lib/waarp/${WAARP_APPNAME}/gwftp.pid

export LOGSERVER=" -Dlogback.configurationFile=${CONFDIR}/logback-server.xml "
export LOGCLIENT=" -Dlogback.configurationFile=${CONFDIR}/logback-client.xml "
export LOGGWFTP=" -Dlogback.configurationFile=${CONFDIR}/logback-gwftp.xml "

#export R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"
#export FTP_CLASSPATH="/usr/share/waarp/gwftp-lib/WaarpGatewayFtp-${WAARP_GWFTP_VERSION}.jar:/usr/share/waarp/gwftp-lib/*"

export JAVARUNCLIENT="${JAVA_RUN} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGCLIENT} "
export JAVARUNSERVER="${JAVA_RUN} ${JAVA_OPTS1} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGSERVER} "
export JAVARUNFTPSERVER="${JAVA_RUN} ${JAVA_OPTS1} ${JAVA_OPTS2} -cp ${FTP_CLASSPATH} ${LOGGWFTP} "

echo --------------------------------------------------
echo 'Initializing Waarp command line tools'
echo --------------------------------------------------
. /usr/share/waarp/init-commands.sh

if [ ! -f "/etc/waarp/conf.d/${WAARP_APPNAME}/server.xml" ]; then
    mkdir -p "/etc/waarp/conf.d/${WAARP_APPNAME}"
    cp -v /etc/waarp/conf.d/template/*.xml /etc/waarp/conf.d/${WAARP_APPNAME}/
fi

echo --------------------------------------------------
echo 'Initializing Waarp password file'
echo --------------------------------------------------
WAARP_CRYPTED_PASSWORD=$(
    java -cp "${R66_CLASSPATH}" org.waarp.uip.WaarpPassword -pwd "${WAARP_ADMIN_PASSWORD}" \
    -des -ko "/etc/waarp/certs/cryptokey.des" \
    -po "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" 2>&1 | \
    grep "CryptedPwd:" | sed 's#CryptedPwd\:\s##g' \
)

xmlstarlet ed -P -S -L \
-u "/config/identity/hostid" -v "${WAARP_APPNAME}" \
-u "/config/identity/sslhostid" -v "${WAARP_APPNAME}-ssl" \
-u "/config/identity/cryptokey" -v "/etc/waarp/certs/cryptokey.des" \
-u "/config/identity/authentfile" -v "/etc/waarp/conf.d/${WAARP_APPNAME}/OpenR66-authent.xml" \
-u "/config/server/serverpasswd" -v "${WAARP_CRYPTED_PASSWORD}" \
${SERVER_CONFIG}

echo --------------------------------------------------
echo 'Initializing Waarp SSL'
echo --------------------------------------------------
# Admin     --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" ]; then
    echo "Generating admin key"
    
    keytool -noprompt -genkey -keysize ${WAARP_KEYSIZE} -keyalg ${WAARP_KEYALG} \
    -sigalg ${WAARP_SIGALG} -validity "${WAARP_KEYVAL}" \
    -alias "${WAARP_APPNAME}_admkey" \
    -dname "${WAARP_SSL_DNAME}" \
    -keystore "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" \
    -storepass "${WAARP_ADMKEYSTOREPASS}" \
    -keypass "${WAARP_ADMKEYPASS}"

    xmlstarlet ed -P -S -L \
    -u "/config/server/admkeypath" -v "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" \
    -u "/config/server/admkeystorepass" -v ${WAARP_ADMKEYSTOREPASS}  \
    -u "/config/server/admkeypass" -v ${WAARP_ADMKEYPASS} \
    ${SERVER_CONFIG}
fi

# Server    --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_server.jks" ]; then
    echo "Generating server key"
    
    keytool -noprompt -genkey -keysize ${WAARP_KEYSIZE} -keyalg ${WAARP_KEYALG} \
    -sigalg ${WAARP_SIGALG} -validity "${WAARP_KEYVAL}" \
    -alias "${WAARP_APPNAME}_server" \
    -dname "${WAARP_SSL_DNAME}" \
    -keystore "/etc/waarp/certs/${WAARP_APPNAME}_server.jks" \
    -storepass "${WAARP_KEYSTOREPASS}" \
    -keypass "${WAARP_KEYPASS}"

    xmlstarlet ed -P -S -L \
    -u "/config/ssl/keypath" -v "/etc/waarp/certs/${WAARP_APPNAME}_server.jks" \
    -u "/config/ssl/keystorepass" -v ${WAARP_KEYSTOREPASS}  \
    -u "/config/ssl/keypass" -v ${WAARP_KEYPASS} \
    ${SERVER_CONFIG}
fi

# Trust    --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_trust.jks" ]; then
    echo "Generating trust key"
    
    keytool -noprompt -genkey -keysize ${WAARP_KEYSIZE} -keyalg ${WAARP_KEYALG} \
    -sigalg ${WAARP_SIGALG} -validity "${WAARP_KEYVAL}" \
    -alias "${WAARP_APPNAME}_trust" \
    -dname "${WAARP_SSL_DNAME}" \
    -keystore "/etc/waarp/certs/${WAARP_APPNAME}_trust.jks" \
    -storepass "${WAARP_TRUSTKEYSTOREPASS}"  \
    -keypass "${WAARP_TRUSTKEYSTOREPASS}"

    xmlstarlet ed -P -S -L \
    -u "/config/ssl/trustkeypath" -v "/etc/waarp/certs/${WAARP_APPNAME}_trust.jks" \
    -u "/config/ssl/trustkeystorepass" -v ${WAARP_TRUSTKEYSTOREPASS} \
    ${SERVER_CONFIG}
fi

echo --------------------------------------------------
echo 'Initializing Waarp password file'
echo --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" ]; then
    echo "Generating admin key"
    
    keytool -noprompt -genkey -keysize ${WAARP_KEYSIZE} -keyalg ${WAARP_KEY_ALG} \
    -alias "${WAARP_APPNAME}_admkey" \
    -dname "{WAARP_SSL_DNAME}"
    -keystore "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" \
    -storepass "${WAARP_ADMKEYSTOREPASS}" \
    -keypass "${WAARP_ADMKEYPASS}"

    xmlstarlet ed -P -S -L \
    -u "/config/server/admkeypath" -v 
    -u "/config/server/admkeystorepass" -v ${WAARP_ADMKEYSTOREPASS}  \
    -u "/config/server/admkeypass" -v ${WAARP_ADMKEYPASS}
fi

echo --------------------------------------------------
echo 'Initializing Waarp password file'
echo --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" ]; then
    echo "Generating admin key"
    
    keytool -noprompt -genkey -keysize ${WAARP_KEYSIZE} -keyalg ${WAARP_KEY_ALG} \
    -alias ${WAARP_APPNAME}_admkey \
    -dname {WAARP_SSL_DNAME}
    -keystore /etc/waarp/certs/${WAARP_APPNAME}_admkey.jks \
    -storepass ${WAARP_ADMKEYSTOREPASS} \
    -keypass ${WAARP_ADMKEYPASS}

    xmlstarlet ed -P -S -L \
    -u "/config/server/admkeystorepass" -v ${WAARP_ADMKEYSTOREPASS}  \
    -u "/config/server/admkeypass" -v ${WAARP_ADMKEYPASS}
fi

echo --------------------------------------------------
echo 'Initializing Waarp authentication XML file'
echo --------------------------------------------------
if [ ! -f "/etc/waarp/conf.d/${WAARP_APPNAME}/OpenR66-authent.xml" ]; then
    echo '<?xml version="1.0" encoding="UTF-8"?><authent xmlns:x0="http://www.w3.org/2001/XMLSchema"></authent>' | xmlstarlet ed \
    -s "/authent" -t elem -n entry -v "" \
    -s "/authent/entry" -t elem -n hostid -v ${WAARP_APPNAME} \
    -s "/authent/entry" -t elem -n address -v "127.0.0.1" \
    -s "/authent/entry" -t elem -n port -v "6666" \
    -s "/authent/entry" -t elem -n isssl -v "false" \
    -s "/authent/entry" -t elem -n admin -v "false" \
    -s "/authent/entry" -t elem -n keyfile -v "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" \
    -s "/authent" -t elem -n entry -v "" \
    -s "/authent/entry" -t elem -n hostid -v "${WAARP_APPNAME}-ssl" \
    -s "/authent/entry" -t elem -n address -v "127.0.0.1" \
    -s "/authent/entry" -t elem -n port -v "6667" \
    -s "/authent/entry" -t elem -n isssl -v "true" \
    -s "/authent/entry" -t elem -n admin -v "true" \
    -s "/authent/entry" -t elem -n keyfile -v "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" \
    > /etc/waarp/conf.d/${WAARP_APPNAME}/OpenR66-authent.xml
fi

echo --------------------------------------------------
echo 'Initializing Waarp Database'
echo --------------------------------------------------
if [ -z ${MYSQL_ENV_GOSU_VERSION+x} ]; then
    echo "Database engine is not MySQL/MariaDB"
else
    echo "Database engine is MySQL/MariaDB"
    : ${WAARP_DATABASE_TYPE='mysql'}
    : ${WAARP_DATABASE_USER:=${MYSQL_ENV_MYSQL_USER:-root}}
    if [ "$WAARP_DATABASE_USER" = 'root' ]; then
        : ${WAARP_DATABASE_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
    fi
    : ${WAARP_DATABASE_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
    : ${WAARP_DATABASE_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-squashtm}}
    : ${WAARP_DATABASE_URL="jdbc:mysql://mysql:3306/$WAARP_DATABASE_NAME"}

    if [ -z "$WAARP_DATABASE_PASSWORD" ]; then
        echo >&2 'error: missing required WAARP_DATABASE_PASSWORD environment variable'
        echo >&2 '  Did you forget to -e WAARP_DATABASE_PASSWORD=... ?'
        echo >&2
        echo >&2 '  (Also of interest might be WAARP_DATABASE_USER and WAARP_DATABASE_NAME.)'
        exit 1
    fi
fi

if [ -z ${POSTGRES_ENV_GOSU_VERSION+x} ]; then
    echo "Database engine is not PostgreSQL"
else
    echo "Database engine is PostgreSQL"
    : ${WAARP_DATABASE_TYPE='postgresql'}
    : ${WAARP_DATABASE_USER:=${POSTGRES_ENV_POSTGRES_USER:-root}}
    if [ "$WAARP_DATABASE_USER" = 'postgres' ]; then
        : ${WAARP_DATABASE_PASSWORD:='postgres' }
    fi
    : ${WAARP_DATABASE_PASSWORD:=$POSTGRES_ENV_POSTGRES_PASSWORD}
    : ${WAARP_DATABASE_NAME:=${POSTGRES_ENV_POSTGRES_DB:-squashtm}}
    : ${WAARP_DATABASE_URL="jdbc:postgresql://postgres:5432/$WAARP_DATABASE_NAME"}

    if [ -z "$WAARP_DATABASE_PASSWORD" ]; then
        echo >&2 'error: missing required WAARP_DATABASE_PASSWORD environment variable'
        echo >&2 '  Did you forget to -e WAARP_DATABASE_PASSWORD=... ?'
        echo >&2
        echo >&2 '  (Also of interest might be WAARP_DATABASE_USER and WAARP_DATABASE_NAME.)'
        exit 1
    fi
fi

xmlstarlet ed -P -S -L \
-u "/config/db/dbdriver" -v "${WAARP_DATABASE_TYPE}" \
-u "/config/db/dbserver" -v "${WAARP_DATABASE_URL}"  \
-u "/config/db/dbuser" -v "${WAARP_DATABASE_USER}" \
-u "/config/db/dbpasswd" -v "${WAARP_DATABASE_PASSWORD}" \
${SERVER_CONFIG}

${R66INIT} -initdb
${R66INIT} -auth /etc/waarp/conf.d/${WAARP_APPNAME}/OpenR66-authent.xml
${R66INIT} -upgradedb

echo --------------------------------------------------
echo 'Waarp init process complete; ready for start up.'
echo --------------------------------------------------

/usr/bin/waarp-r66server ${WAARP_APPNAME} start
