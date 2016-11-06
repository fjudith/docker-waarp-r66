#!/bin/sh
# R66 HOME
export R66BIN="/usr/share/waarp/r66-lib"

export JAVAEXECCLIENT="java -cp ${R66_CLASSPATH} ${LOGCLIENT} -Dopenr66.locale=en -Dfile.encoding=UTF-8 "
export JAVAEXECSERVER="java -cp ${R66_CLASSPATH} ${LOGSERVER} -Dopenr66.locale=en -Dfile.encoding=UTF-8 "

export R66_CLASSPATH="/usr/share/waarp/r66-lib/WaarpR66-${WAARP_R66_VERSION}.jar:/usr/share/waarp/r66-lib/*"
export FTP_CLASSPATH="/usr/share/waarp/gwftp-lib/WaarpGatewayFtp-${WAARP_GWFTP_VERSION}.jar:/usr/share/waarp/gwftp-lib/*"

export SERVER_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/server.xml"
export CLIENT_CONFIG="/etc/waarp/conf.d/${WAARP_APPNAME}/client.xml"

################
# R66 COMMANDS #
################

# SERVER SIDE #
###############
# start the OpenR66 server
# no option
export R66SERVER="/usr/bin/waarp-r66server"
alias r66server="${R66SERVER} ${WAARP_APPNAME} start "

# init database from argument
# [ -initdb ] [ -loadBusiness businessConfiguration ] [ -loadRoles roleConfiguration ] [ -loadAlias aliasConfig ] [ -dir rulesDirectory ] [ -limit xmlFileLimit ] [ -auth xmlFileAuthent ] [ -upgradeDb ]
export R66INIT="${JAVAEXECCLIENT} org.waarp.openr66.server.ServerInitDatabase ${SERVER_CONFIG} "
alias r66init="${R66INIT}"

# export configuration into directory
# directory
export R66CNFEXP="${JAVAEXECCLIENT} org.waarp.openr66.server.ServerExportConfiguration ${SERVER_CONFIG} "
alias r66cnfexp="${R66CNFEXP}"

# export configuration as arguments
# [-hosts] [-rules] [-business ] [-alias] [-roles] [-host host]
export R66CONFEXP="${JAVAEXECCLIENT} org.waarp.openr66.server.ConfigExport ${SERVER_CONFIG} "
alias r66confexp="${R66CONFEXP}"

# import configuration as arguments
# [-hosts host-configuration-file] [-purgehosts] [-rules rule-configuration-file] [-purgerules] [-business file] [-purgebusiness] [-alias file] [-purgealias] [-roles file] [-purgeroles] [-hostid file transfer id] [-ruleid file transfer id] [-businessid file transfer id] [-aliasid file transfer id] [-roleid file transfer id] [-host host]
export R66CONFIMP="${JAVAEXECCLIENT} org.waarp.openr66.server.ConfigImport ${SERVER_CONFIG} "
alias r66confimp="${R66CONFIMP}"

# shutdown locally the server
# [ PID ] optional PID of the server process
export R66SIGNAL="${R66HOME}/bin/localshutdown.sh"
alias r66signal="${R66SIGNAL}"

# shutdown by network the server
# [-nossl|-ssl] default = -ssl
export R66SHUTD="${JAVAEXECCLIENT} org.waarp.openr66.server.ServerShutdown ${SERVER_CONFIG} "
alias r66shutd="${R66SHUTD}"

# export the log
# [ -purge ] [ -clean ] [ -start timestamp ] [ -stop timestamp ] where timestamp are in yyyyMMddHHmmssSSS format eventually truncated and with possible ':- ' as separators
export R66EXPORT="${JAVAEXECCLIENT} org.waarp.openr66.server.LogExport ${SERVER_CONFIG} "
alias r66export="${R66EXPORT}"

# export the log (extended)
# [-host host [-ruleDownload rule [-import]]] [ -purge ] [ -clean ] [-startid id] [-stopid id] [-rule rule] [-request host] [-pending] [-transfer] [-done] [-error] [ -start timestamp ] [ -stop timestamp ] where timestamp are in yyyyMMddHHmmssSSS format eventually truncated and with possible ':- ' as separators
export R66LOGEXPORT="${JAVAEXECCLIENT} org.waarp.openr66.server.LogExtendedExport ${SERVER_CONFIG} "
alias r66logexport="${R66LOGEXPORT}"

# import the log (should be used on another server)
# exportedLogFile
export R66LOGIMPORT="${JAVAEXECCLIENT} org.waarp.openr66.server.LogImport ${SERVER_CONFIG} "
alias r66logimport="${R66LOGIMPORT}"

# change limits of bandwidth
# "[ -wglob x ] [ -rglob w ] [ -wsess x ] [ -rsess x ]"
export R66LIMIT="${JAVAEXECCLIENT} org.waarp.openr66.server.ChangeBandwidthLimits ${SERVER_CONFIG} "
alias r66limit="${R66LIMIT}"

# Administrator Gui
# no argument
export R66ADMIN="${JAVAEXECCLIENT} org.waarp.administrator.AdminGui ${SERVER_CONFIG} "
alias r66admin="${R66ADMIN}"

# CLIENT SIDE #
###############

# asynchronous transfer
# (-to hostId -file filepath -rule ruleId) | (-to hostId -id transferId) [ -md5 ] [ -block size ] [ -nolog ] [-start yyyyMMddHHmmssSSS | -delay +durationInMilliseconds | -delay preciseTimeInMilliseconds] [ -info "information" ]
export R66SEND="${JAVAEXECCLIENT} org.waarp.openr66.client.SubmitTransfer ${CLIENT_CONFIG} "
alias r66send="${R66SEND}"

# synchronous transfer
# (-to hostId -file filepath -rule ruleId) | (-to hostId -id transferId) [ -md5 ] [ -block size ] [ -nolog ] [-start yyyyMMddHHmmssSSS | -delay +durationInMilliseconds | -delay preciseTimeInMilliseconds] [ -info "information" ]
export R66SYNCSEND="${JAVAEXECCLIENT} org.waarp.openr66.client.DirectTransfer ${CLIENT_CONFIG} "
alias r66syncsend="${R66SYNCSEND}"

# get information on transfers
# (-id transferId -to hostId as requested | -id transferId -from hostId as requester) 
# follow by one of: (-cancel | -stop | -restart [ -start yyyyMMddHHmmss | -delay +durationInMilliseconds | -delay preciseTimeInMilliseconds ]
export R66REQ="${JAVAEXECCLIENT} org.waarp.openr66.client.RequestTransfer ${CLIENT_CONFIG} "
alias r66req="${R66REQ}"

# get information on remote files or directory
# "-to host -rule rule [ -file file ] [ -exist | -detail | -list | -mlsx ]
export R66INFO="${JAVAEXECCLIENT} org.waarp.openr66.client.RequestInformation  ${CLIENT_CONFIG} "
alias r66info="${R66INFO}"

# test the connectivity
# -to host -msg "message"
export R66MESG="${JAVAEXECCLIENT} org.waarp.openr66.client.Message ${CLIENT_CONFIG} "
alias r66mesg="${R66MESG}"

# R66 Gui
# no argument
export R66GUI="${JAVAEXECCLIENT} org.waarp.openr66.r66gui.R66ClientGui ${CLIENT_CONFIG} "
alias r66gui="${R66GUI}"

# R66 Multiple Submit
# (-to hostId,hostID -file filepath,filepath -rule ruleId) | (-to hostId -id transferId) [ -md5 ] [ -block size ] [ -nolog ] [-start yyyyMMddHHmmssSSS | -delay +durationInMilliseconds | -delay preciseTimeInMilliseconds] [ -info "information" ]
export R66MULTISEND="${JAVAEXECCLIENT} org.waarp.openr66.client.MultipleSubmitTransfer ${CLIENT_CONFIG} "
alias r66multisend="${R66MULTISEND}"

# R66 Multiple synchronous transfer
# (-to hostId,hostid -file filepath,filepath -rule ruleId) | (-to hostId -id transferId) [ -md5 ] [ -block size ] [ -nolog ] [-start yyyyMMddHHmmssSSS | -delay +durationInMilliseconds | -delay preciseTimeInMilliseconds] [ -info "information" ]
export R66MULTISYNCSEND="${JAVAEXECCLIENT} org.waarp.openr66.client.MultipleDirectTransfer ${CLIENT_CONFIG} "
alias r66multisyncsend="${R66MULTISYNCSEND}"

# R66 Spooled directory transfer
# (-to hostId,hostid -directory directory -statusfile file -stopfile file -rule ruleId) [-md5] [-block size] [-nolog ] [-elapse elapse] [-regex regex] [-submit|-direct] [-info "information"]
export R66SPOOLEDSEND="${JAVAEXECCLIENT} org.waarp.openr66.client.SpooledDirectoryTransfer ${CLIENT_CONFIG} "
alias r66spooledsend="${R66MULTISYNCSEND}"
