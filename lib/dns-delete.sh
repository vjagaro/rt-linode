echo "Deleting DNS records for $LINODE_LABEL..."

_rt_require_linode

echo

LINODE_DOMAIN_BASENAME="${SERVER_FQDN%.$LINODE_DOMAIN}"

lib/linode-domain-record.sh delete4 \
  --linode-cli ".venv/bin/linode-cli" \
  --as-user "$LINODE_DOMAIN_USER" \
  --domain "$LINODE_DOMAIN" \
  --name "$LINODE_DOMAIN_BASENAME"

lib/linode-domain-record.sh delete6 \
  --linode-cli ".venv/bin/linode-cli" \
  --as-user "$LINODE_DOMAIN_USER" \
  --domain "$LINODE_DOMAIN" \
  --name "$LINODE_DOMAIN_BASENAME"

echo
echo "Deleted DNS records for $LINODE_LABEL."
