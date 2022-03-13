echo "Updating linode $LINODE_LABEL..."

_rt_require_linode
_rt_server_upload_conf
cat lib/server-install.sh | _rt_server_ssh bash -s

echo "Updated $LINODE_LABEL."
