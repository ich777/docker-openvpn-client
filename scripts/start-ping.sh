#!/bin/bash
if [ -z "${PING_COUNT}" ]; then
  PING_COUNT=1
fi
if [ -z "${PING_PACKET_TIMEOUT}" ]; then
  PING_PACKET_TIMEOUT=10
fi
if [ -z "${PING_INTERVAL}" ]; then
  PING_INTERVAL=30
fi

sleep 10
while true; do
  if ! ping -c ${PING_COUNT} -W ${PING_PACKET_TIMEOUT} ${PING_IP} >/dev/null 2>&1 ; then
    echo "---Ping from ${PING_IP} failed, restarting container,...---"
    kill -SIGKILL $(pidof openvpn)
  fi
  sleep ${PING_INTERVAL}s
done