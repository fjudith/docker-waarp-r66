#!/bin/bash
#set -x
# Waap Internal Name

JAVA_XMX=${WAARP_XMX:-512m}
JAVA_XMS=${WAARP_XMS:-256m}

export WAARP_APPNAME=${WAARP_APPNAME:-"server1"}
export WAARP_DATABASE_LANGUAGE=${WAARP_DATABASE_LANGUAGE:-"en"}
export WAARP_ADMIN_PASSWORD=${WAARP_ADMIN_PASSWORD:-"password"}

export JAVA_HOME=$(readlink -f $(dirname $(readlink -f $(which java)))/..)
export JAVA_OPTS1="-server"
export JAVA_OPTS2="-Xms${JAVA_XMS} -Xmx${JAVA_XMX}"
export JAVA_RUN="${JAVA_HOME}/bin/java"

export PATH=${JAVA_HOME}/bin:$PATH

export CONFDIR=${CONFDIR:-/etc/waarp/conf.d/$WAARP_APPNAME}
export PIDFILE=/var/lib/waarp/${WAARP_APPNAME}/r66server.pid

export SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/server.xml"
export CLIENT_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/client.xml"
export LOGSERVER=" -Dlogback.configurationFile=${CONFDIR}/logback-gwftp.xml "
export LOGCLIENT=" -Dlogback.configurationFile=${CONFDIR}/logback-client.xml "

export JAVARUNCLIENT="${JAVA_RUN} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGCLIENT} "
export JAVARUNSERVER="${JAVA_RUN} ${JAVA_OPTS1} ${JAVA_OPTS2} -cp ${R66_CLASSPATH} ${LOGSERVER} "

export R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"

source /usr/share/waarp/init-commands.sh

# Initializing Command Line Tools.
# The script contains command line tools
# to interact with Waarp engine.
# e.g initialize database, submit/list transfer requests.
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Initializing Waarp command line tools'

#source /usr/share/waarp/variables.sh

# Waarp Database configuration
# --------------------------------------------------
export WAARP_DATABASE_TYPE=${WAARP_DATABASE_TYPE:-"h2"}
export WAARP_DATABASE_NAME=${WAARP_DATABASE_NAME:-"${WAARP_APPNAME}_waarp"}
export WAARP_DATABASE_USER=${WAARP_DATABASE_USER:-"waarp"}
export WAARP_DATABASE_PASSWORD=${WAARP_DATABASE_PASSWORD:-"waarp"}
export WAARP_DATABASE_CHECK=${WAARP_DATABASE_CHECK:-"false"}

if [ "${WAARP_DATABASE_TYPE}" == "h2" ]; then
    export WAARP_DATABASE_URL=${WAARP_DATABASE_URL:-"jdbc:${WAARP_DATABASE_TYPE}:/var/lib/waarp/${WAARP_APPNAME}/db/${WAARP_DATABASE_NAME};MODE=ORACLE;AUTO_SERVER=TRUE"}
elif [ "${WAARP_DATABASE_TYPE}" == "mysql" ]; then
    export WAARP_DATABASE_HOST=${WAARP_DATABASE_HOST:-'mysql'}

    export WAARP_DATABASE_URL="jdbc:mysql://${WAARP_DATABASE_HOST}:3306/$WAARP_DATABASE_NAME"
elif [ "${WAARP_DATABASE_TYPE}" == "postgresql" ]; then
    export WAARP_DATABASE_HOST=${WAARP_DATABASE_HOST:-'postgresql'}

    export WAARP_DATABASE_URL="jdbc:postgresql://${WAARP_DATABASE_HOST}:5432/$WAARP_DATABASE_NAME"
fi

### Wait for Postgres
function waitfor-postgres {
    until psql -h "${WAARP_DATABASE_HOST}" -c '\q'; do
        >&2 echo "Postgres is unavailable: Sleeping"
        sleep 1
    done
}



# SSL
# --------------------------------------------------
export WAARP_SSL_DNAME=${WAARP_SSL_DNAME:-"CN=${WAARP_APPNAME}\, OU=xfer\, O=MyCompany\, L=Paris\, S=Paris\, C=FR"}
export WAARP_KEYSIZE=${WAARP_KEYSIZE:-"2048"}
export WAARP_KEYALG=${WAARP_KEYALG:-"RSA"}
export WAARP_SIGALG=${WAARP_SIGALG:-"SHA256withRSA"}
export WAARP_KEYVAL=${WAARP_KEYVAL:-"3650"}
export WAARP_ADMKEYSTOREPASS=${WAARP_ADMKEYSTOREPASS:-"password"}
export WAARP_ADMKEYPASS=${WAARP_ADMKEYPASS-"password"}
export WAARP_KEYSTOREPASS=${WAARP_KEYSTOREPASS:-"password"}
export WAARP_KEYPASS=${WAARP_KEYPASS:-"password"}
export WAARP_TRUSTKEYSTOREPASS=${WAARP_TRUSTKEYSTOREPASS:-"password"}

# SNMP
# --------------------------------------------------
export WAARP_SNMP_AUTHPASS=${WAARP_SNMP_AUTHPASS:-"password"}
export WAARP_SNMP_PRIVPASS=${WAARP_SNMP_PRIVPASS:-"password"}

# Deploying XML configuration files.
# Copy the configuration from Template,
# if not already customized
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Deploying XML configuration files if required'

if [ ! -f ${SERVER_CONFIG} ]; then
    mkdir -v -p "/etc/waarp/conf.d/${WAARP_APPNAME}"
    mkdir -v -p "/etc/waarp/certs"
    cp -vn /tmp/conf.d/template/*.xml /etc/waarp/conf.d/${WAARP_APPNAME}/
fi


# Initializing Directories.
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Initializing Directories.'

mkdir -v -p "/var/lib/waarp/${WAARP_APPNAME}"

# File Transfer directory 
mkdir -v -p "/var/lib/waarp/${WAARP_APPNAME}/xfer"

# File watcher dirctory
mkdir -v -p "/var/lib/waarp/${WAARP_APPNAME}/spool"

# File watcher flags dirctory
mkdir -v -p "/var/lib/waarp/${WAARP_APPNAME}/flags"

# Server
xmlstarlet ed -P -S -L \
-u "/config/directory/serverhome" -v "/var/lib/waarp/${WAARP_APPNAME}" \
${SERVER_CONFIG}

# Client
xmlstarlet ed -P -S -L \
-u "/config/directory/serverhome" -v "/var/lib/waarp/${WAARP_APPNAME}" \
${CLIENT_CONFIG}


# Initializing Waarp Password file.
# Update password if key already exists.
# --------------------------------------------------
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" ]; then
	echo $(date --rfc-3339=seconds) 'Initializing Waarp password file'
	WAARP_CRYPTED_PASSWORD=$(
    	java -cp "${R66_CLASSPATH}" org.waarp.uip.WaarpPassword -pwd "${WAARP_ADMIN_PASSWORD}" \
	    -des -ko "/etc/waarp/certs/cryptokey.des" \
	    -po "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" 2>&1 | \
	    grep "CryptedPwd:" | sed 's#CryptedPwd\:\s##g' \
	)
else
	echo $(date --rfc-3339=seconds) 'Updating Waarp password file'
	WAARP_CRYPTED_PASSWORD=$(
    	java -cp "${R66_CLASSPATH}" org.waarp.uip.WaarpPassword -pwd "${WAARP_ADMIN_PASSWORD}" \
	    -des -ki "/etc/waarp/certs/cryptokey.des" \
	    -po "/etc/waarp/certs/${WAARP_APPNAME}-admin-passwd.ggp" 2>&1 | \
	    grep "CryptedPwd:" | sed 's#CryptedPwd\:\s##g' \
	)
fi

xmlstarlet ed -P -S -L \
-u "/config/identity/hostid" -v "${WAARP_APPNAME}" \
-u "/config/identity/sslhostid" -v "${WAARP_APPNAME}-ssl" \
-u "/config/identity/cryptokey" -v "/etc/waarp/certs/cryptokey.des" \
-u "/config/identity/authentfile" -v "/etc/waarp/conf.d/${WAARP_APPNAME}/authent-server.xml" \
-u "/config/server/serverpasswd" -v "${WAARP_CRYPTED_PASSWORD}" \
-u "/config/business/businessid" -v "${WAARP_APPNAME}" \
-u "/config/business/businessid" -v "${WAARP_APPNAME}-ssl" \
${SERVER_CONFIG}

xmlstarlet ed -P -S -L \
-u "/config/identity/hostid" -v "${WAARP_APPNAME}" \
-u "/config/identity/sslhostid" -v "${WAARP_APPNAME}-ssl" \
-u "/config/identity/cryptokey" -v "/etc/waarp/certs/cryptokey.des" \
-u "/config/identity/authentfile" -v "/etc/waarp/conf.d/${WAARP_APPNAME}/authent-server.xml" \
-u "/config/server/serverpasswd" -v "${WAARP_CRYPTED_PASSWORD}" \
${CLIENT_CONFIG}

# Initializing Waarp authentication XML file.
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Initializing Waarp authentication XML file'

if [ ! -f "/etc/waarp/conf.d/${WAARP_APPNAME}/authent-server.xml" ]; then
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
    > /etc/waarp/conf.d/${WAARP_APPNAME}/authent-server.xml
fi


# Initializing Waarp SSL
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Initializing Waarp SSL'

# Admin
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_admkey.jks" ]; then
    echo $(date --rfc-3339=seconds) "Generating admin key"
    
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

# Server
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_server.jks" ]; then
    echo $(date --rfc-3339=seconds) "Generating server key"
    
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

    xmlstarlet ed -P -S -L \
    -u "/config/ssl/keypath" -v "/etc/waarp/certs/${WAARP_APPNAME}_server.jks" \
    -u "/config/ssl/keystorepass" -v ${WAARP_KEYSTOREPASS}  \
    -u "/config/ssl/keypass" -v ${WAARP_KEYPASS} \
    ${CLIENT_CONFIG}
fi

# Trust
if [ ! -f "/etc/waarp/certs/${WAARP_APPNAME}_trust.jks" ]; then
    echo $(date --rfc-3339=seconds) "Generating trust key"
    
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

    xmlstarlet ed -P -S -L \
    -u "/config/ssl/trustkeypath" -v "/etc/waarp/certs/${WAARP_APPNAME}_trust.jks" \
    -u "/config/ssl/trustkeystorepass" -v ${WAARP_TRUSTKEYSTOREPASS} \
    ${CLIENT_CONFIG}
fi

# REST API
if [ ! -f "/etc/waarp/certs/restsigning.key" ]; then
    cat /dev/urandom | head -c64 > /etc/waarp/certs/restsigning.key
fi

# Initializing Waarp SNMP file
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 'Initializing Waarp SNMP file'

xmlstarlet ed -P -S -L \
-u "/config/server/snmpconfig" -v "/etc/waarp/conf.d/${WAARP_APPNAME}/snmpconfig.xml" \
${SERVER_CONFIG}

xmlstarlet ed -P -S -L \
-u "/snmpconfig/securities/security/securityauthpass" -v ${WAARP_SNMP_AUTHPASS} \
-u "/snmpconfig/securities/security/securityprivpass" -v ${WAARP_SNMP_PRIVPASS} \
/etc/waarp/conf.d/${WAARP_APPNAME}/snmpconfig.xml

echo $(date --rfc-3339=seconds) 'Initializing Waarp Database'

# Initializing Waarp MySQL Database
# --------------------------------------------------
if [ ! -z ${MYSQL_ENV_GOSU_VERSION} ]; then
    echo $(date --rfc-3339=seconds) "Database engine is MySQL/MariaDB"
    
    WAARP_DATABASE_TYPE='mysql'
    WAARP_DATABASE_USER=${MYSQL_ENV_MYSQL_USER:-root}

    if [ "$WAARP_DATABASE_USER" = 'root' ]; then
        WAARP_DATABASE_PASSWORD=$MYSQL_ENV_MYSQL_ROOT_PASSWORD
    fi
    
    WAARP_DATABASE_PASSWORD=$MYSQL_ENV_MYSQL_PASSWORD
    WAARP_DATABASE_NAME=${MYSQL_ENV_MYSQL_DATABASE:-waarp}
    WAARP_DATABASE_HOST=${WAARP_DATABASE_HOST:-mysql}
    WAARP_DATABASE_URL="jdbc:mysql://${WAARP_DATABASE_HOST}:3306/$WAARP_DATABASE_NAME"

    if [ -z "$WAARP_DATABASE_PASSWORD" ]; then
        echo >&2 'error: missing required WAARP_DATABASE_PASSWORD environment variable'
        echo >&2 '  Did you forget to -e WAARP_DATABASE_PASSWORD=... ?'
        echo >&2
        echo >&2 '  (Also of interest might be WAARP_DATABASE_USER and WAARP_DATABASE_NAME.)'
        exit 1
    fi
fi

# Initializing Waarp PosgreSQL Database
# --------------------------------------------------
if [ ! -z ${POSTGRES_ENV_GOSU_VERSION}  ]; then
    echo $(date --rfc-3339=seconds) "Database engine is PostgreSQL"
   
    WAARP_DATABASE_TYPE='postgresql'
    WAARP_DATABASE_USER=${POSTGRES_ENV_POSTGRES_USER:-root}

    if [ "$WAARP_DATABASE_USER" = 'postgres' ]; then
        WAARP_DATABASE_PASSWORD='postgres'
    fi
    
    WAARP_DATABASE_PASSWORD=$POSTGRES_ENV_POSTGRES_PASSWORD
    WAARP_DATABASE_NAME=${POSTGRES_ENV_POSTGRES_DB:-waarp}
    WAARP_DATABASE_HOST=${WAARP_DATABASE_HOST:-postgres}
    WAARP_DATABASE_URL="jdbc:postgresql://${WAARP_DATABASE_HOST}:5432/$WAARP_DATABASE_NAME"

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
-u "/config/db/dbcheck" -v "${WAARP_DATABASE_CHECK}" \
${SERVER_CONFIG}

xmlstarlet ed -P -S -L \
-u "/config/db/dbdriver" -v "${WAARP_DATABASE_TYPE}" \
-u "/config/db/dbserver" -v "${WAARP_DATABASE_URL}"  \
-u "/config/db/dbuser" -v "${WAARP_DATABASE_USER}" \
-u "/config/db/dbpasswd" -v "${WAARP_DATABASE_PASSWORD}" \
${CLIENT_CONFIG}

# Populating Waarp Database
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 
echo $(date --rfc-3339=seconds) 'Database tables'
echo $(date --rfc-3339=seconds) --------------------------------------------------
/usr/bin/waarp-r66server ${WAARP_APPNAME} initdb

echo $(date --rfc-3339=seconds) 
echo $(date --rfc-3339=seconds) 'Authentication data'
echo $(date --rfc-3339=seconds) --------------------------------------------------
/usr/bin/waarp-r66server ${WAARP_APPNAME} loadauth /etc/waarp/conf.d/${WAARP_APPNAME}/authent-server.xml


# Start Waarp-R66
# --------------------------------------------------
echo $(date --rfc-3339=seconds) 
echo $(date --rfc-3339=seconds) 'Waarp init process completed; ready for start up.'
echo $(date --rfc-3339=seconds) --------------------------------------------------
/usr/bin/waarp-r66server ${WAARP_APPNAME} start