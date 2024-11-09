#!/bin/bash

/usr/local/bin/openvpn.sh &
sleep 30
ARGS=$(ps -ef |grep openvpn |grep -v grep |sed 's/.*openvpn //' |head -n1)

while [ true ]; do
        ping -c1 1.1.1.1 > /dev/null
        if (( $? != 0 )); then
                sleep 30
                ping -c1 8.8.8.8 > /dev/null
                if (( $? != 0 )); then
                        sleep 30
                        ping -c1 1.1.1.1 > /dev/null
                        if (( $? != 0 )); then
                                echo "Reconnecting"
                                echo "============"
                                if [ -n "${ARGS}" ]; then
                                        pkill -15 openvpn
                                fi
                                sleep 10
                                openvpn $ARGS &
                        fi
                fi
        fi
        sleep 60
done
