#!/bin/bash
pacman --noconfirm -S openbsd-netcat
echo "---Starting connected containers watchdog on 127.0.0.1:27286---"
(sleep 10 && nc 127.0.0.1 27286 && { echo "---Connection to connected container lost, restarting in 15 seconds...---"; sleep 15; kill -SIGTERM 1; } || echo "---Couldn't connect to connected containers---") &