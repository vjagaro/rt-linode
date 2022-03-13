echo "Showing client..."

_rt_report_client

echo

qrencode -t ansiutf8 <"$CLIENT_CONFIG"
