#!/bin/bash
# This script sends the file in argument to the sftp-client
set -e

sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no waarp@localhost <<-End-Of-Session
	cd "/var/lib/waarp/ftp/sftp/in"
	put -P $1
	quit
End-Of-Session

rm $1
