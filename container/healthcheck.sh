#!/bin/sh

set -e

RCC_STATUS=~"/.rccontrol-profile/bin/rccontrol-status"

# No need to chain <= set -e

"${RCC_STATUS}" community-1 2>/dev/null | grep -q RUNNING

"${RCC_STATUS}" vcsserver-1 2>/dev/null | grep -q RUNNING
