#!/bin/bash
echo "---Starting service for connected containers on port: $WATCH_PORT---"
socat TCP-LISTEN:${WATCH_PORT},fork EXEC:"/bin/cat"