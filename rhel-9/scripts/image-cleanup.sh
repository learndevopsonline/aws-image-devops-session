#!/bin/bash

## Final step before creating the AMI from a build instance: start the image with
## empty logs and no shell history from the build (same as end of ami-setup.sh).

truncate -s 0 `find /var/log -type f |xargs`
rm -f /root/.bash_history /home/*/.bash_history
rm -rf /tmp/*
