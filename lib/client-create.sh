echo "Creating client..."

mkdir -p clients

test -f clients/index || echo 0 >clients/index

INDEX=$(($(cat clients/index) + 1))
CLIENT_ADDRESS="$WG_IPV4_NET.$INDEX, $WG_IPV6_NET::$INDEX"
CLIENT_CONFIG="clients/$INDEX-client.conf"
CLIENT_PRIVATE_KEY="$(wg genkey)"
CLIENT_PUBLIC_KEY="$(echo $CLIENT_PRIVATE_KEY | wg pubkey)"

_rt_report_client

echo $INDEX >clients/index

touch "$CLIENT_CONFIG"
chmod 600 "$CLIENT_CONFIG"
cat <<-END >"$CLIENT_CONFIG"
[Interface]
Address = $CLIENT_ADDRESS
DNS = $WG_IPV4_NET.$WG_LAST_OCTET, $WG_IPV6_NET::$WG_LAST_OCTET
PrivateKey = $CLIENT_PRIVATE_KEY

[Peer]
PublicKey = $(echo $WG_PRIVATE_KEY | wg pubkey)
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_FQDN:$WG_PORT
END

echo

qrencode -t ansiutf8 <"$CLIENT_CONFIG"
