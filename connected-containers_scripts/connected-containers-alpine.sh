#!/bin/sh
apk update
apk add netcat-openbsd
(nc 127.0.0.1 27286 && { echo "---Connection to connected container lost, restarting in 5 seconds...---"; sleep 5; kill -SIGTERM 1; } || echo "---Couldn't connect to connected containers---") &
