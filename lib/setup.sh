echo "Running setup..."

if _rt_detect_termux; then

  echo "Detected Android Termux..."
  pkg install -y git libqrencode mosh ncurses-utils netcat-openbsd openssh \
    openssl-tool python wireguard-tools
  test -d .venv || python -m venv .venv

else

  echo "Assuming Debian..."
  sudo apt-get update
  sudo apt-get install -y git mosh ncurses-bin openssh-client openssl netcat \
    python3 python3-pip qrencode wireguard
  test -d .venv || python3 -m venv .venv

fi

.venv/bin/pip install -U pip wheel setuptools
.venv/bin/pip install -U linode-cli

if ! test -f rt.conf; then
  echo "Creating rt.conf..."
  cp rt.conf.example rt.conf
  chmod 600 rt.conf
  perl -pi -e "s|^(PIHOLE_PASSWORD=).*|\${1}\"$(openssl rand -hex 8)\"|" rt.conf
  perl -pi -e "s|^(WG_PRIVATE_KEY=).*|\${1}\"$(wg genkey)\"|" rt.conf
fi

if ! test -f "$HOME/.config/linode-cli"; then
  echo "Configuring linode-cli..."
  _rt_linode_cli configure
fi
