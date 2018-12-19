#!/bin/bash
# This script sends the file in argument to the sftp-client
set -e

sftp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no waarp@localhost <<-End-Of-Session
	cd /var/lib/waarp/ftp/sftp/out/
	get $1
	rm $1
	quit
End-Of-Session

waarp-r66client gwftp send -file $1 -to server2 -rule fromSFTP