FROM alpine:latest

LABEL MAINTAINER Richard Lochner, Clone Research Corp. <lochner@clone1.com> \
      org.label-schema.name = "openvpn" \
      org.label-schema.description = "OpenVPN Container" \
      org.label-schema.vendor = "Clone Research Corp" \
      org.label-schema.usage = "https://github.com/lochnerr/openvpn" \
      org.label-schema.url = "https://openvpn.net/community-resources/how-to/" \
      org.label-schema.vcs-url = "https://github.com/lochnerr/openvpn.git"

# A simple openvpn container.
#
# Volumes:
#  * /etc/openvpn - directory for openvpn config files.
#
# Exposed ports:
#  * 1194 - Default OpenVPN port.
#
# Linux capabilities required:
#  * ALL - Must be privileged to create /dev/tun and/or /dev/tap devices.

RUN apk add --update --no-cache openvpn openssl tini easy-rsa bash openssh

RUN mv /usr/share/easy-rsa/* /usr/local/bin/ \
 && sed \
      # Don't want to force certificate renewal often.
      -e "s:#set_var EASYRSA_CERT_EXPIRE.*:set_var EASYRSA_CERT_EXPIRE	3650:" \
      # Want to be able to renew sooner than 30 days.
      -e "s:#set_var EASYRSA_CERT_RENEW.*:set_var EASYRSA_CERT_RENEW	180:" \
      # Don't want to be forced to renew CRL often.
      -e "s:#set_var EASYRSA_CRL_DAYS.*:set_var EASYRSA_CRL_DAYS	3650:" \
      # Enable elliptic curve support.
      -e "s:#set_var EASYRSA_ALGO.*:set_var EASYRSA_ALGO		ec:" \
      # Set elliptic curve.
      -e "s:#set_var EASYRSA_CURVE.*:set_var EASYRSA_CURVE		secp521r1:" \
      /usr/local/bin/vars.example > /usr/local/bin/vars \
 && mv /etc/openvpn /etc/openvpn-bak \
 && mkdir /etc/openvpn

COPY bin/. /usr/local/bin/

VOLUME  /etc/openvpn
WORKDIR /etc/openvpn

EXPOSE 1194/udp

ENTRYPOINT ["/sbin/tini", "-v", "--"]
CMD ["/usr/sbin/openvpn","--config","/etc/openvpn/openvpn.conf"]

