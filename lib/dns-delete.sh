echo "Deleting DNS records for $LINODE_LABEL..."

LINODE_DNS_COMMAND="delete"

source "lib/dns-common.sh"

echo
echo "Deleted DNS records for $LINODE_LABEL."
