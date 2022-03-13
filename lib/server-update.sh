echo "Updating $LINODE_LABEL..."

_rt_require_linode

echo

_rt_server_upload_conf

echo

cat lib/server-install.sh | _rt_server_ssh bash -s

echo
echo "Updated $LINODE_LABEL."
