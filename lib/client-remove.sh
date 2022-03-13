echo "Removing client $CLIENT_CONFIG..."

PRIVATE_KEY="$(cat "$CLIENT_CONFIG" | grep '^PrivateKey =' |
  sed 's/PrivateKey = //')"
PUBLIC_KEY="$(echo "$PRIVATE_KEY" | wg pubkey)"

echo "Client has public key $PUBLIC_KEY..."

_rt_require_linode

cat <<-EOF | _rt_server_ssh bash -s
wg set "$WG_IFACE" peer "$PUBLIC_KEY" remove
wg-quick save "$WG_IFACE" 2>/dev/null
EOF

echo "Removed peer $PUBLIC_KEY from linode $LINODE_LABEL."

rm -f "$CLIENT_CONFIG"

if test "$(find clients -name '*.conf' | wc -l)" = "0"; then
  rm clients/index
fi

echo "Removed client $CLIENT_CONFIG."
