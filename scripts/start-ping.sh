#!/bin/bash
sleep 10
while true; do
  if ! ping -c 1 -W 10 ${PING_IP} >/dev/null 2>&1 ; then
    echo "---Ping from ${PING_IP} failed, restarting container,...---"
    kill 1
  fi
  sleep ${PING_INTERVAL}s
done