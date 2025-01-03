#!/bin/bash

set -e -u -o pipefail

#activate_firewall based on code from dperson/openvpn-client
activate_firewall() {
  # the VPN Port
  local port=1197
  # the ip of the docker network
  #local dock_net=$(ip -o addr show dev eth0 | 
  local dock_nets=$(ip -o addr show |grep eth |
                         awk '$3 == "inet" {print $4}')
  # if the ovpn file exists, try to set the port from the file
  if [ -r "/pia/${CONNECTIONSTRENGTH}/${REGION}.ovpn" ]; then
    port=$(awk '/^remote / && NF ~ /^[0-9]*$/ {print $NF}' "/pia/${CONNECTIONSTRENGTH}/${REGION}.ovpn" |
           grep ^ || echo 1197)
  fi

  iptables -F OUTPUT
  iptables -P OUTPUT DROP
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A OUTPUT -o tun+ -j ACCEPT
  #iptables -A OUTPUT -d ${dock_net} -j ACCEPT
  for dock_net in ${dock_nets}; do
    iptables -A OUTPUT -d ${dock_net} -j ACCEPT
  done
  iptables -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp -m owner --gid-owner openvpn -j ACCEPT 2>/dev/null &&
  iptables -A OUTPUT -p udp -m owner --gid-owner openvpn -j ACCEPT || {
    iptables -A OUTPUT -p tcp -m tcp --dport $port -j ACCEPT
    iptables -A OUTPUT -p udp -m udp --dport $port -j ACCEPT;
  }
}

ARGS=

if [ -n "$REGION" ]; then
  REGION=`echo ${REGION// /_} | awk '{print tolower($0)}'`
else
  REGION=us_east
fi
if [ -n "$CONNECTIONSTRENGTH" ]; then
  CONNECTIONSTRENGTH=`echo ${CONNECTIONSTRENGTH} | awk '{print tolower($0)}'`
else
  CONNECTIONSTRENGTH=strong
fi

ARGS="${ARGS}--config /pia/${CONNECTIONSTRENGTH}/${REGION}.ovpn"


if [ -n "${USERNAME:-""}" -a -n "${PASSWORD:-""}" ]; then
  echo "$USERNAME" > auth.conf
  echo "$PASSWORD" >> auth.conf
  chmod 600 auth.conf
  ARGS="$ARGS --auth-user-pass auth.conf"
fi

for ARG in $@; do
  ARGS="$ARGS \"$ARG\""
done

activate_firewall

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
  mknod -m 0666 /dev/net/tun c 10 200
fi

echo "Args: $ARGS"
openvpn $ARGS
