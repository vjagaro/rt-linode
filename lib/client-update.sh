echo "Updating client $CLIENT_CONFIG..."

ADDRESS="$(cat "$CLIENT_CONFIG" | grep '^Address = ' | sed 's/.* = //')"
PRIVATE_KEY="$(cat "$CLIENT_CONFIG" | grep '^PrivateKey = ' | sed 's/.* = //')"
PUBLIC_KEY="$(echo "$PRIVATE_KEY" | wg pubkey)"

echo "Client has public key $PUBLIC_KEY."

_rt_require_linode

cat <<-EOF | _rt_server_ssh bash -s
wg set "$WG_IFACE" peer "$PUBLIC_KEY" allowed-ips "$ADDRESS"
wg-quick save "$WG_IFACE" 2>/dev/null
EOF

echo "Updated peer $PUBLIC_KEY on linode $LINODE_LABEL."
