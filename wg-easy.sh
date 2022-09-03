#!bin/bash
apk add socat
socat TCP-LISTEN:6001,fork TCP:10.8.0.4:6001 &
/usr/bin/dumb-init node server.js
