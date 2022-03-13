echo "Creating client..."

mkdir -p clients

test -f clients/index || echo 0 >clients/index

INDEX=$(($(cat clients/index) + 1))
ADDRESS="$WG_IPV4_NET.$INDEX, $WG_IPV6_NET::$INDEX"
CLIENT_CONFIG="clients/$INDEX-client.conf"
PRIVATE_KEY="$(wg genkey)"
PUBLIC_KEY="$(echo $PRIVATE_KEY | wg pubkey)"

echo $INDEX >clients/index

touch "$CLIENT_CONFIG"
chmod 600 "$CLIENT_CONFIG"
cat <<-END >"$CLIENT_CONFIG"
[Interface]
Address = $ADDRESS
DNS = $WG_IPV4_NET.$WG_LAST_OCTET, $WG_IPV6_NET::$WG_LAST_OCTET
PrivateKey = $PRIVATE_KEY

[Peer]
PublicKey = $(echo $WG_PRIVATE_KEY | wg pubkey)
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_FQDN:$WG_PORT
END

echo "Created client $CLIENT_CONFIG."

echo "Client has public key $PUBLIC_KEY."

_rt_require_linode

cat <<-EOF | _rt_server_ssh bash -s
wg set "$WG_IFACE" peer "$PUBLIC_KEY" allowed-ips "$ADDRESS"
wg-quick save "$WG_IFACE" 2>/dev/null
EOF

echo "Added peer $PUBLIC_KEY to linode $LINODE_LABEL."

