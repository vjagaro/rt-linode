echo "Getting status for linode $LINODE_LABEL..."

_rt_linode_cli --as-user "$LINODE_USER" \
  --format label,id,ipv4,ipv6,region,status \
  linodes list --label "$LINODE_LABEL"
