#!/bin/sh

# Fix ownership on each invocation
sudo chown -R `id -u`.`id -g` \
    ~/.rccontrol/community-1 \
    ~/.rccontrol/vcsserver-1 \
    ~/repos

exec supervisord -c ~/.rccontrol/supervisor/supervisord.ini
