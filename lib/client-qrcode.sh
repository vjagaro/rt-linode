echo "QR Code for client $CLIENT_CONFIG:"
echo

qrencode -t ansiutf8 <"$CLIENT_CONFIG"
