#!/bin/bash
if ! [[ "$CONNECTED_CONTAINERS" =~ ^[0-9]+$ ]] || [ "$CONNECTED_CONTAINERS" -lt 1024 ] || [ "$CONNECTED_CONTAINERS" -gt 65535 ]; then
  echo "---The variable CONNECTED_CONTAINERS is not set properly!---"
  echo "---Please set it to a value between 1024 and 65535---"
  exit 1
fi

echo "---Starting service for connected containers on port: $CONNECTED_CONTAINERS---"
socat TCP-LISTEN:${CONNECTED_CONTAINERS},fork EXEC:"/bin/cat"