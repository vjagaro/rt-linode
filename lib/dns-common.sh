_rt_require_linode

LINODE_DOMAIN_BASENAME="${SERVER_FQDN%.$LINODE_DOMAIN}"

LINODE_DOMAIN_ID="$(_rt_linode_cli --as-user "$LINODE_DOMAIN_USER" --text \
  --no-header --format id domains list --domain "$LINODE_DOMAIN")"

if [ -z "$LINODE_DOMAIN_ID" ]; then
  echo >&2 "ERROR: Linode domain $LINODE_DOMAIN not found."
  exit 1
fi

echo
echo "Linode domain:    $LINODE_DOMAIN"
echo "Linode domain ID: $LINODE_DOMAIN_ID"
echo

LINODE_DOMAIN_RECORD_IPV4_ID=""
LINODE_DOMAIN_RECORD_IPV6_ID=""

while read line; do
  read -a a <<<"$line"
  id="${a[0]}"
  match="${a[1]}:${a[2]:-}"
  if [ "$match" = "A:$LINODE_DOMAIN_BASENAME" ]; then
    LINODE_DOMAIN_RECORD_IPV4_ID="$id"
  elif [ "$match" = "AAAA:$LINODE_DOMAIN_BASENAME" ]; then
    LINODE_DOMAIN_RECORD_IPV6_ID="$id"
  fi

done <<<$(_rt_linode_cli --as-user "$LINODE_DOMAIN_USER" --text \
  --no-header --format id,type,name \
  domains records-list "$LINODE_DOMAIN_ID")

for type in A AAAA; do
  if [ "$type" = "A" ]; then
    text="IPv4"
    id="$LINODE_DOMAIN_RECORD_IPV4_ID"
    target="$LINODE_IPV4"
  else
    text="IPv6"
    id="$LINODE_DOMAIN_RECORD_IPV6_ID"
    target="$LINODE_IPV6"
  fi

  if [ "${LINODE_DNS_COMMAND:-}" = "delete" ]; then
    if [ -n "$id" ]; then
      echo "Deleting $text record..."
      echo "  $SERVER_FQDN"
      _rt_linode_cli --as-user "$LINODE_DOMAIN_USER" domains records-delete \
        "$LINODE_DOMAIN_ID" "$id" >/dev/null
    fi
  elif [ -n "$id" ]; then
    echo "Updating $text record..."
    echo "  $SERVER_FQDN -> $target"
    _rt_linode_cli --as-user "$LINODE_DOMAIN_USER" domains records-update \
      --type $type --name "$LINODE_DOMAIN_BASENAME" \
      --target "$target" --ttl_sec "$LINODE_DOMAIN_TTL" \
      "$LINODE_DOMAIN_ID" "$id" >/dev/null
  else
    echo "Creating $text record..."
    echo "  $SERVER_FQDN -> $target"
    _rt_linode_cli --as-user "$LINODE_DOMAIN_USER" domains records-create \
      --type $type --name "$LINODE_DOMAIN_BASENAME" \
      --target "$target" --ttl_sec "$LINODE_DOMAIN_TTL" \
      "$LINODE_DOMAIN_ID" >/dev/null
  fi
done
