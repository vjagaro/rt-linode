echo "Connecting to $LINODE_LABEL..."

_rt_require_linode

echo

shift 2
_rt_server_ssh "$@"
