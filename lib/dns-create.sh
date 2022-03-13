echo "Creating DNS records for $LINODE_LABEL..."

LINODE_DNS_COMMAND="create"

source "lib/dns-common.sh"

echo "Created DNS records for $LINODE_LABEL."
