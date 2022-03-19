#!/bin/bash

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 [OPTIONS] <COMMAND> ...

Simple Linode domain record getter / setter.

Commands:
  get4                     Get the IPv4 record.
  get6                     Get the IPv6 record.
  set4                     Set the IPv4 record.
  set6                     Set the IPv6 record.
  delete4                  Delete the IPv4 record.
  delete6                  Delete the IPv6 record

Required arguments:
  -d|--domain DOMAIN       The domain.
  -n|--name NAME           The name.
  -t|--target TARGET       The target [set only].

Optional arguments:
  -h|--help                This help text.
     --ttl TTL             The time-to-live [set only].
  -u|--as-user USERNAME    The Linode username to execute as.
  -l|--linode-cli PATH     The path to linode-cli.
  -q|--quiet               Suppress / minimize output.
EOF
  exit 1
}

_info() {
  if [ -z "$QUIET" ]; then
    echo "$@"
  fi
}

_linode_cli() {
  [ -n "$USERNAME" ] && set -- --as-user "$USERNAME" "$@"
  "$LINODE_CLI" "$@"
}

_require_arg() {
  if [ $# -lt 2 ]; then
    echo >&2 "ERROR: Missing argument to $1."
    usage
    exit 1
  fi
}

COMMAND=""
DOMAIN=""
unset NAME
TARGET=""
TTL="0"
USERNAME=""
LINODE_CLI="linode-cli"
QUIET=""

ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
  -d | --domain)
    _require_arg "$@"
    DOMAIN="$2"
    shift 2
    ;;
  -n | --name)
    _require_arg "$@"
    NAME="$2"
    shift 2
    ;;
  -t | --target)
    _require_arg "$@"
    TARGET="$2"
    shift 2
    ;;
  --ttl)
    _require_arg "$@"
    TTL="$2"
    shift 2
    ;;
  -u | --as-user)
    _require_arg "$@"
    USERNAME="$2"
    shift 2
    ;;
  -l | --linode-cli)
    _require_arg "$@"
    LINODE_CLI="$2"
    shift 2
    ;;
  -q | --quiet)
    QUIET=1
    shift
    ;;
  -h | --help)
    usage
    ;;
  get4 | set4 | delete4)
    COMMAND="$1"
    TYPE="A"
    shift
    ;;
  get6 | set6 | delete6)
    COMMAND="$1"
    TYPE="AAAA"
    shift
    ;;
  *)
    echo >&2 "ERROR: Unknown command / option $1."
    usage
    ;;
  esac
done

if [ -z "$COMMAND" ]; then
  usage
elif [ -z "$DOMAIN" ]; then
  echo >&2 "ERROR: Missing domain."
  usage
elif [ -z "${NAME+x}" ]; then
  echo >&2 "ERROR: Missing name."
  usage
elif [ -z "$TARGET" ]; then
  if [ "$COMMAND" = "set4" ] || [ "$COMMAND" = "set6" ]; then
    echo >&2 "ERROR: Missing target."
    usage
  fi
fi

_info -n "Querying domain $DOMAIN..."

DOMAIN_ID="$(_linode_cli --text --no-header --format id domains list \
  --domain "$DOMAIN")"

if [ -z "$DOMAIN_ID" ]; then
  _info >&2 "error!"
  _info >&2 "Domain $DOMAIN not found."
  exit 1
fi

_info

FQDN="$NAME$([ -n "$NAME" ] && echo . || true)$DOMAIN"

_info -n "Querying domain records of $DOMAIN..."

records="$(_linode_cli --text --no-header --format id,type,name,target \
  --delimiter , domains records-list "$DOMAIN_ID")"

_info

if [ "$COMMAND" = "get4" ] || [ "$COMMAND" = "get6" ]; then

  while read line; do
    IFS="," read -a a <<<"$line"
    match="${a[1]}:${a[2]}"
    if [ "$match" = "$TYPE:$NAME" ]; then
      if [ -z "$QUIET" ]; then
        _info "$FQDN ($TYPE): ${a[3]}"
      else
        echo "${a[3]}"
      fi
      exit 0
    fi
  done <<<"$records"

  if [ -z "$QUIET" ]; then
    _info "$FQDN ($TYPE): No record"
  else
    echo
  fi

else

  unset RECORD_ID
  unset EXISTING
  while read line; do
    IFS="," read -a a <<<"$line"
    id="${a[0]}"
    match="${a[1]}:${a[2]}"
    if [ "$match" = "$TYPE:$NAME" ]; then
      RECORD_ID="$id"
      EXISTING="${a[3]}"
      break
    fi
  done <<<"$records"

  if [ "$COMMAND" = "delete4" ] || [ "$COMMAND" = "delete6" ]; then
    if [ -z "${RECORD_ID+x}" ]; then
      _info "No record for $FQDN ($TYPE)."
    else
      _info -n "Deleting $FQDN ($TYPE)..."
      _linode_cli domains records-delete "$DOMAIN_ID" "$id" >/dev/null
      _info
    fi
  elif [ -z "${RECORD_ID+x}" ]; then
    _info -n "Creating $FQDN ($TYPE): $TARGET..."
    _linode_cli domains records-create \
      --type $TYPE --name "$NAME" --target "$TARGET" --ttl_sec "$TTL" \
      "$DOMAIN_ID" >/dev/null
    _info
  elif [ "$TARGET" = "$EXISTING" ]; then
    _info "Exists $FQDN ($TYPE): $TARGET, not updating."
  else
    _info -n "Updating $FQDN ($TYPE): $TARGET..."
    _linode_cli domains records-update \
      --type $TYPE --name "$NAME" --target "$TARGET" --ttl_sec "$TTL" \
      "$DOMAIN_ID" "$RECORD_ID" >/dev/null
    _info
  fi

fi
