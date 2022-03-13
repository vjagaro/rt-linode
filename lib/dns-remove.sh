echo "Removing DNS records for $LINODE_LABEL..."

LINODE_DNS_COMMAND="remove"

source "lib/dns-common.sh"

echo "Removed DNS records for $LINODE_LABEL."
