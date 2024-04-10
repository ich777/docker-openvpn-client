#!/bin/bash
echo "---Starting service for connected containers on port: $CONNECTED_CONTAINERS---"
socat TCP-LISTEN:${CONNECTED_CONTAINERS},fork EXEC:"/bin/cat"