# rt-linode

Linode / WireGuard routing tool.

## Install

```sh
apt install -y git # or pkg install -y git
git clone https://github.com/vjagaro/rt-linode.git
cd rt-linode
./rt setup
```

Review and edit `rt.conf`.

## Usage

```
Usage: ./rt <COMMAND> ...

  ./rt client create       Create a new client
  ./rt client list         List clients
  ./rt client qrcode <N>   Show QR code for client N
  ./rt client remove <N>   Remove client N
  ./rt client update <N>   Update client N
  ./rt dns create          Create DNS records
  ./rt dns remove          Remove DNS records
  ./rt dns update          Update DNS records
  ./rt server create       Create the server
  ./rt server remove       Remove the server
  ./rt server ssh          SSH into server
  ./rt server status       Show the server status
  ./rt server update       Update the server
  ./rt setup               Run the initial setup
```
