echo "Syncing $LINODE_LABEL..."

_rt_require_linode

tmp="$(mktemp)"

cat <<EOF >"$tmp"
set -euo pipefail

WG_IFACE="$WG_IFACE"
pubkeys=()
addresses=()
peers=()
changes=0

EOF

shopt -s nullglob
for config in clients/*.conf; do
  pubkey="$(grep "^PrivateKey = " "$config" | sed 's/.* = //' | wg pubkey)"
  echo "pubkeys+=('$pubkey')" >>"$tmp"
  address="$(grep "^Address = " "$config" | sed 's/.* = //')"
  echo "addresses+=('$address')" >>"$tmp"
done

cat <<'EOF' >>"$tmp"

while read peer; do
  [ -n "$peer" ] && peers+=("$peer")
done <<<$(wg show "$WG_IFACE" peers)

i=0
for pubkey in "${pubkeys[@]}"; do
  match=
  for peer in "${peers[@]}"; do
    if [ "$pubkey" = "$peer" ]; then
      match=1
      break
    fi
  done
  if [ -z "$match" ]; then
    wg set "$WG_IFACE" peer "$pubkey" allowed-ips "${addresses[$i]}"
    changes=$(($changes + 1))
    echo "Added peer $pubkey."
  fi
  i=$(($i + 1))
done

for peer in "${peers[@]}"; do
  match=
  for pubkey in "${pubkeys[@]}"; do
    if [ "$peer" = "$pubkey" ]; then
      match=1
      break
    fi
  done
  if [ -z "$match" ]; then
    wg set "$WG_IFACE" peer "$peer" remove
    changes=$(($changes + 1))
    echo "Removed peer $peer."
  fi
done

wg-quick save "$WG_IFACE" 2>/dev/null

if [ $changes -eq 0 ]; then
  echo "No changes."
fi
EOF

echo

cat "$tmp" | _rt_server_ssh bash -s

rm -f "$tmp"

echo
echo "Synced $LINODE_LABEL."
