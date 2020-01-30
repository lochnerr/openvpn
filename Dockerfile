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


# Secure the ssh daemon configuration.
RUN cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.bak \
 && sed -i \
   -e 's:^#HostKey.*/etc/ssh/ssh_host_ed25519_key:HostKey /etc/ssh/ssh_host_ed25519_key:' \
   -e '/^# Ciphers and keying.*/a KexAlgorithms curve25519-sha256@libssh.org\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com' \
   -e 's:^#LogLevel.*:LogLevel VERBOSE:' \
   -e 's:^Subsystem.*sftp.*:Subsystem	sftp	/usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO:' \
   /etc/ssh/sshd_config

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
 # Create a testing key for ssh
 && mkdir -p /etc/testing \
 && ssh-keygen -t ed25519 -N "" -f /etc/testing/id_ed25519_testing -C "testing@example.com" \
 && mv /etc/openvpn /etc/openvpn-bak \
 && mkdir /etc/openvpn

COPY bin/. /usr/local/bin/
COPY testing/dh*.pem /etc/testing/

VOLUME  /etc/openvpn
WORKDIR /etc/openvpn

EXPOSE 1194/udp

ENTRYPOINT ["/sbin/tini", "-v", "--"]
CMD ["/usr/sbin/openvpn","--config","/etc/openvpn/openvpn.conf"]

