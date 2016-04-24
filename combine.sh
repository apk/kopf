#!/bin/sh
cd "`dirname "$0"`"
cat src/mailer.rb src/cron.rb src/cfg.rb src/jobset.rb src/runner.rb test.rb | grep -v require_relative
