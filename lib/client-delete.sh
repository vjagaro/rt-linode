echo "Deleting client..."

_rt_report_client

rm -f "$CLIENT_CONFIG"

if test "$(find clients -name '*.conf' | wc -l)" = "0"; then
  rm clients/index
fi

echo
echo "Deleted client."
