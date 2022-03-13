echo "Client configs:"

shopt -s nullglob
for config in clients/*.conf; do
  echo "  $config:"
  echo -n "    public key:  "
  grep "^PrivateKey = " "$config" | sed 's/.* = //' | wg pubkey
  echo -n "    allowed ips: "
  grep "^Address = " "$config" | sed 's/.* = //'
done

_rt_require_linode

echo "Server peers:"

echo "wg | tail -n +6 | grep -v '^$' | sed 's/^/  /g'" | _rt_server_ssh bash -s
