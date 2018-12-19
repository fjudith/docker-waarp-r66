#!/bin/bash
# This script reloads the configuration of a Waarp R66 or Waarp Gateway
# FTP instance.
#
# It can be run as a postttrasnfer task to reload the configuration
# that was just transfered.
#
# TODO: decide if it should be included in waarp-ctl
set -e

CURDIR=$(cd $(dirname $0) && pwd)
cd $CURDIR

XMLDIR=$1
tmp=${XMLDIR%/*}
SERVERNAME=${tmp##*/}

[[ -n ${XMLDIR} ]] || exit 2

waarp-r66server $SERVERNAME loadauth ${XMLDIR}/authent.xml || exit 2
waarp-r66server $SERVERNAME loadrule ${XMLDIR}  || exit 2

if [[ -f ${XMLDIR}/gwftp_authent.xml ]]; then
    mv ${XMLDIR}/gwftp_authent.xml /etc/conf.d/$SERVERNAME/gwftp_authent.xml
fi


rm -f ${XMLDIR}/authent.xml ${XMLDIR}/*.rules.xml  || exit 2