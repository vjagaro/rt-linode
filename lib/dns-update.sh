echo "Updating DNS records for $LINODE_LABEL..."

LINODE_DNS_COMMAND="update"

source "lib/dns-common.sh"

echo
echo "Updated DNS records for $LINODE_LABEL."
