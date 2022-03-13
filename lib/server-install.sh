set -euo pipefail

_rt_apt_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q ' installed'
}

_rt_apt_ensure() {
  local pkg
  for pkg in "$@"; do
    _rt_apt_installed "$pkg" ||
      DEBIAN_FRONTEND=noninteractive _rt_indent apt-get install -qqy "$pkg"
  done
}

_rt_indent() {
  {
    "$@" 2>&1 1>&3 |
      sed -u 's/^\(.*\)/  \x1b[31m\1\x1b[0m/'
  } 3>&1 1>&2 |
    sed -u 's/^\(.*\)/  \x1b[37m\1\x1b[0m/'
}

source /etc/rt.conf
chmod 600 /etc/rt.conf

echo "Adding a regular user..."
getent group "$SERVER_REGULAR_USER" >/dev/null ||
  groupadd "$SERVER_REGULAR_USER"
getent passwd "$SERVER_REGULAR_USER" >/dev/null ||
  useradd -m -g "$SERVER_REGULAR_USER" -s /bin/bash "$SERVER_REGULAR_USER"

# Ensure it can sudo
echo "$SERVER_REGULAR_USER ALL=(ALL:ALL) NOPASSWD: ALL" \
  >"/etc/sudoers.d/$SERVER_REGULAR_USER"
chmod 440 "/etc/sudoers.d/$SERVER_REGULAR_USER"

# Ensure it can SSH
mkdir -p "/home/$SERVER_REGULAR_USER/.ssh"
chmod 700 "/home/$SERVER_REGULAR_USER/.ssh"
cp -f "/root/.ssh/authorized_keys" \
  "/home/$SERVER_REGULAR_USER/.ssh/authorized_keys"
chmod 600 "/home/$SERVER_REGULAR_USER/.ssh/authorized_keys"
chown "$SERVER_REGULAR_USER:$SERVER_REGULAR_USER" -R \
  "/home/$SERVER_REGULAR_USER/.ssh"

echo "Removing the root password..."

perl -pi -e 's/^(root):[^:]*:(.*)$/$1:!:$2/' /etc/shadow

echo "Disabling SSH password authentication..."

perl -pi -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' \
  /etc/ssh/sshd_config
_rt_indent systemctl restart ssh

echo "Updating package index..."

_rt_indent apt-get update -q

echo "Upgrading packages..."

DEBIAN_FRONTEND=noninteractive _rt_indent apt-get upgrade -qqy

SERVER_HOSTNAME="$(echo $SERVER_FQDN | cut -d. -f1)"

echo "Configuring hostname..."

echo "$SERVER_HOSTNAME" >/etc/hostname
hostname -F /etc/hostname

echo "Configuring /etc/hosts..."

cat <<-EOF >/etc/hosts
# /etc/hosts
127.0.0.1       localhost
127.0.1.1       $SERVER_HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

echo "Configuring firewall..."

_rt_apt_ensure nftables

PUBLIC_IFACE=$(ip route ls default | awk '{print $5}')

if [ -z "$PUBLIC_IFACE" ]; then
  echo >&2 "ERROR: Could not get public interface."
  exit 1
fi

cat <<-EOF >/etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority filter; policy accept;

    iifname "lo" accept
    ct state { established, related } counter accept
    ct state invalid counter drop
    ip protocol icmp counter accept
    ip6 nexthdr ipv6-icmp counter accept

    iifname { "$PUBLIC_IFACE", "$WG_IFACE" } tcp dport ssh counter accept
    iifname { "$PUBLIC_IFACE", "$WG_IFACE" } udp dport 60000-61000 counter accept
    iifname "$WG_IFACE" tcp dport { http, https } counter accept
    iifname "$WG_IFACE" tcp dport domain counter accept
    iifname "$WG_IFACE" udp dport domain counter accept
    iifname "$PUBLIC_IFACE" udp dport $WG_PORT counter accept

    counter reject
  }

  chain forward {
    type filter hook forward priority filter; policy accept;
    ct state { established, related } counter accept
    iifname "$WG_IFACE" oifname { "$PUBLIC_IFACE", "$WG_IFACE" } counter accept
    counter reject
  }

  chain output {
    type filter hook output priority filter; policy accept;
    counter accept
  }

  chain prerouting {
    type nat hook prerouting priority dstnat; policy accept;
    counter accept
  }

  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    iifname "$WG_IFACE" oifname "$PUBLIC_IFACE" counter masquerade
    counter accept
  }
}
EOF

_rt_indent systemctl enable nftables
_rt_indent systemctl restart nftables

echo "Enabling IP forwarding..."

cat <<-EOF >/etc/sysctl.d/ip_forwarding.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

_rt_indent sysctl --quiet --system

echo "Installing Mosh..."

_rt_apt_ensure mosh

echo "Installing network utilities..."

_rt_apt_ensure nmap tcpdump

echo "Installing automatic upgrades..."

_rt_apt_ensure unattended-upgrades apt-listchanges

echo "Installing WireGuard..."

_rt_apt_ensure wireguard

echo "Configuring WireGuard..."

touch /etc/wireguard/$WG_IFACE.conf
chmod 600 /etc/wireguard/$WG_IFACE.conf

cat <<-EOF >/etc/wireguard/$WG_IFACE.conf
[Interface]
Address = $WG_IPV4_NET.$WG_LAST_OCTET/24
Address = $WG_IPV6_NET::$WG_LAST_OCTET/64
SaveConfig = true
ListenPort = $WG_PORT
PrivateKey = $WG_PRIVATE_KEY
EOF

_rt_indent systemctl enable wg-quick@$WG_IFACE
_rt_indent systemctl start wg-quick@$WG_IFACE

echo "Installing PiHole..."

mkdir -p /etc/pihole
touch /etc/pihole/setupVars.conf
chmod 600 /etc/pihole/setupVars.conf
cat <<EOF >/etc/pihole/setupVars.conf
WEBPASSWORD=$(echo -n $PIHOLE_PASSWORD | sha256sum | awk '{printf "%s",$1}' | sha256sum | awk '{printf "%s",$1}')
PIHOLE_INTERFACE=$WG_IFACE
IPV4_ADDRESS=$WG_IPV4_NET.$WG_LAST_OCTET
IPV6_ADDRESS=$WG_IPV6_NET::$WG_LAST_OCTET
QUERY_LOGGING=true
INSTALL_WEB=true
DNSMASQ_LISTENING=single
PIHOLE_DNS_1=1.1.1.1
PIHOLE_DNS_2=1.0.0.1
PIHOLE_DNS_3=2606:4700:4700::1111
PIHOLE_DNS_4=2606:4700:4700::1001
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSSEC=true
TEMPERATUREUNIT=C
WEBUIBOXEDLAYOUT=traditional
API_EXCLUDE_DOMAINS=
API_EXCLUDE_CLIENTS=
API_QUERY_LOG_SHOW=all
API_PRIVACY_MODE=false
EOF

wget -qO- https://install.pi-hole.net | _rt_indent bash /dev/stdin --unattended
