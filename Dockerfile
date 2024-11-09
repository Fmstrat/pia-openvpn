FROM alpine:latest

WORKDIR /pia

RUN \
    apk add --no-cache openvpn curl unzip bash net-tools iptables shadow-login &&\
    curl -sS "https://www.privateinternetaccess.com/openvpn/openvpn-strong.zip" -o /strong.zip &&\
    unzip -q /strong.zip -d /pia/strong &&\
    rm -f /strong.zip &&\
    curl -sS "https://www.privateinternetaccess.com/openvpn/openvpn.zip" -o /normal.zip &&\
    unzip -q /normal.zip -d /pia/normal &&\
    rm -f /normal.zip 

COPY openvpn.sh /usr/local/bin/openvpn.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV REGION=us_east
ENV CONNECTIONSTRENGTH=strong

ENTRYPOINT ["entrypoint.sh"]
