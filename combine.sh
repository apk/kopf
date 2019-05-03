#!/bin/sh
#
# Run this script via 'sh ...repopath/combine.sh' in the directory
# where you want the kopf script.

q="`dirname "$0"`"
head=''
if test -r kopf; then
    # Try to keep original hashbang if present
    head="`head -1 kopf | grep '^#!'`"
fi
if test "X$head" = X; then
    head='#!/usr/bin/ruby'
fi
(
    echo "$head"
    echo "#"
    echo '# kopf: A job runner, see https://github.com/apk/kopf'
    echo "# version/id `git -C "$q" describe --always`"
    echo '#'
    cat \
	"$q"/src/mailer.rb \
	"$q"/src/cron.rb \
	"$q"/src/cfg.rb \
	"$q"/src/jobset.rb \
	"$q"/src/runner.rb \
	"$q"/test.rb | grep -v require_relative
) >kopf
chmod +x kopf

if test -r kopf-msgclt.rb; then
    (
	echo '#'
	echo '# kopf-msgclt: A client for https://github.com/apk/msg, for ./kopf'
	echo "# version/id `git -C "$q" describe --always`"
	echo '#'
	cat "$q"/kopf-msgclt.rb
    ) >kopf-msgclt.rb
fi
