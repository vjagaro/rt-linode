echo "SSHing to linode $LINODE_LABEL..."

_rt_require_linode
shift 2
_rt_server_ssh "$@"
