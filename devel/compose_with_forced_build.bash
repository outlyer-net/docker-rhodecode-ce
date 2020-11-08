#!/bin/bash

cd "$(dirname "$0")/.."

exec docker-compose -f docker-compose.yaml -f <(cat <<EOF

version: '2.4'

services:
  rhodecode:
    # Override docker-compose.yaml's image name to force a build
    image: 'outlyernet/rhodecode-ce.tmp'
EOF
) "$@"