echo "Removing linode $LINODE_LABEL..."

_rt_require_linode
_rt_linode_cli linodes delete "$LINODE_ID"

echo "Removed linode $LINODE_LABEL."

source "lib/dns-remove.sh"
