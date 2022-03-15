echo "Creating $LINODE_LABEL..."

parts="$(
  _rt_linode_cli --as-user "$LINODE_USER" --format id,ipv4,ipv6 \
    --no-headers --text linodes create \
    --authorized_keys "$(cat "$HOME/.ssh/id_ed25519.pub")" \
    --image "$LINODE_IMAGE" \
    --label "$LINODE_LABEL" \
    --region "$LINODE_REGION" \
    --root_pass "$(openssl rand -base64 32)" \
    --type "$LINODE_TYPE"
)"

if [ -z "$parts" ]; then
  echo >&2 "ERROR: Could not create new linode $LINODE_LABEL."
  exit 1
fi

_rt_assign_linode "$parts"
_rt_report_linode

echo

_rt_linode_cli --as-user "$LINODE_USER" --format label,region,type,image \
  linodes list --label "$LINODE_LABEL"

echo

source "lib/dns-set.sh"

echo
echo -n "Waiting for linode $LINODE_LABEL..."

cat <<-EOF | timeout --foreground 120 bash -s
  until nc -w 2 -z "$SERVER_IP" 22; do
    echo -n .
    sleep 1
  done
EOF

echo "ready!"
echo
echo "Installing linode $LINODE_LABEL..."
echo

ssh-keygen -qf "$HOME/.ssh/known_hosts" -R "$LINODE_IPV4" 2>/dev/null
ssh-keygen -qf "$HOME/.ssh/known_hosts" -R "$LINODE_IPV6" 2>/dev/null
ssh-keygen -qf "$HOME/.ssh/known_hosts" -R "$SERVER_FQDN" 2>/dev/null

_rt_server_upload_conf

echo

cat lib/server-install.sh | _rt_server_ssh bash -s

echo
echo "Created linode $LINODE_LABEL."
