echo "Querying $LINODE_LABEL..."

_rt_require_linode

echo

_rt_linode_cli --as-user "$LINODE_USER" --format label,region,type,image \
  linodes list --label "$LINODE_LABEL"

echo

echo "wg show '$WG_IFACE'" | _rt_server_ssh bash -s
