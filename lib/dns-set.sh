echo "Setting DNS records for $LINODE_LABEL..."

_rt_require_linode

echo

LINODE_DOMAIN_BASENAME="${SERVER_FQDN%.$LINODE_DOMAIN}"

lib/linode-domain-record.sh set4 \
  --as-user "$LINODE_DOMAIN_USER" \
  --domain "$LINODE_DOMAIN" \
  --name "$LINODE_DOMAIN_BASENAME" \
  --target "$LINODE_IPV4"

lib/linode-domain-record.sh set6 \
  --as-user "$LINODE_DOMAIN_USER" \
  --domain "$LINODE_DOMAIN" \
  --name "$LINODE_DOMAIN_BASENAME" \
  --target "$LINODE_IPV6"

echo
echo "Set DNS records for $LINODE_LABEL."
