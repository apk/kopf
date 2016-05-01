#!/bin/sh
q="`dirname "$0"`"
(if test -x /opt/rh-ng/ruby-200/root/usr/bin/ruby; then
	echo '#!/opt/rh-ng/ruby-200/root/usr/bin/ruby'
 else
	echo '#!/usr/bin/ruby'
 fi
 cat "$q"/src/mailer.rb "$q"/src/cron.rb "$q"/src/cfg.rb "$q"/src/jobset.rb "$q"/src/runner.rb "$q"/test.rb | grep -v require_relative
) >kopf
chmod +x kopf
