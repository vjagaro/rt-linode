echo "Listing clients..."
echo

first=1
shopt -s nullglob
for config in clients/*.conf; do
  if [ -n "$first" ]; then
    first=
  else
    echo
  fi
  echo "Config:     $config"
  echo -n "Public Key: "
  grep "^PrivateKey = " "$config" | sed 's/.* = //' | wg pubkey
  echo -n "Addresses:  "
  grep "^Address = " "$config" | sed 's/.* = //'
done

[ -n "$first" ] && echo "No clients."
