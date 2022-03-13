echo "Deleting $LINODE_LABEL..."

_rt_require_linode

echo

_rt_linode_cli linodes delete "$LINODE_ID"

echo "Deleted $LINODE_LABEL."
echo

source "lib/dns-delete.sh"
