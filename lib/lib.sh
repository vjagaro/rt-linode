_rt_assign_linode() {
  local a
  read -a a <<<"$1"
  LINODE_ID="${a[0]}"
  LINODE_IPV4="${a[1]}"
  LINODE_IPV6="$(echo "${a[2]}" | sed 's|/.*$||')"
  if [ "$SERVER_CONNECT" = "ipv6" ]; then
    SERVER_IP="$LINODE_IPV6"
  else
    SERVER_IP="$LINODE_IPV4"
  fi
}

_rt_client_find() {
  local conf
  local n="$(echo "$1" | sed 's|^\(.*/\)\?\([0-9]\+\).*$|\2|')"
  if [ -n "$n" ]; then
    conf="$(ls -1 "clients/$n-"*".conf" 2>/dev/null | head -1)"
  else
    conf=""
  fi
  echo "$conf"
}

_rt_detect_termux() {
  test -f "$HOME/../usr/etc/termux-login.sh"
}

_rt_line() {
  perl -E "say '-' x $(tput cols)"
}

_rt_linode_cli() {
  .venv/bin/linode-cli "$@"
}

_rt_load_conf() {
  if ! test -f rt.conf; then
    echo >&2 "ERROR: rt.conf not found."
    exit 1
  fi
  chmod 600 rt.conf
  source rt.conf
}

_rt_require_client_config() {
  local arg="$1"
  CLIENT_CONFIG="$(_rt_client_find "$arg")"
  if [ -z "$CLIENT_CONFIG" ]; then
    echo >&2 "ERROR: Client $arg not found."
    echo >&2
    echo >&2 "To see available clients, try: $0 client list"
    exit 1
  fi
  CLIENT_ADDRESS="$(cat "$CLIENT_CONFIG" | grep '^Address = ' |
    sed 's/.* = //')"
  CLIENT_PRIVATE_KEY="$(cat "$CLIENT_CONFIG" | grep '^PrivateKey = ' |
    sed 's/.* = //')"
  CLIENT_PUBLIC_KEY="$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)"
}

_rt_require_linode() {
  if [ -z "$LINODE_ID" ]; then
    local parts="$(
      _rt_linode_cli --as-user "$LINODE_USER" --format id,ipv4,ipv6 --no-headers \
        --text linodes list --label "$LINODE_LABEL"
    )"
    if [ -z "$parts" ]; then
      echo >&2 -n "ERROR: Could not get IP for linode $LINODE_LABEL."
      echo >&2 " Maybe it doesn't exist?"
      exit 1
    fi
    _rt_assign_linode "$parts"
    _rt_report_linode
  fi
}

_rt_report_client() {
  echo
  echo "Config:     $CLIENT_CONFIG"
  echo "Public key: $CLIENT_PUBLIC_KEY"
  echo "Address:    $CLIENT_ADDRESS"
}

_rt_report_linode() {
  echo
  echo "Linode ID: $LINODE_ID"
  echo "IPv4:      $LINODE_IPV4"
  echo "IPv6:      $LINODE_IPV6"
}

_rt_server_ssh() {
  echo "Connecting to root@$SERVER_IP..."
  _rt_line
  ssh -o "StrictHostKeyChecking no" "root@$SERVER_IP" "$@"
  _rt_line
}

_rt_server_upload_conf() {
  echo "Uploading rt.conf to root@$SERVER_IP..."
  scp -o "StrictHostKeyChecking no" -q rt.conf "root@$SERVER_IP":/etc/rt.conf
}

_rt_setup_termux_ssh() {
  if _rt_detect_termux; then
    local agent_helper="$(which source-ssh-agent || true)"
    if [ -n "$agent_helper" ]; then
      set +e
      source "$agent_helper"
      set -e
    fi
  fi
}
