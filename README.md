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

  ./rt client create       Create a local client
  ./rt client delete <N>   Delete local client N
  ./rt client list         List local clients
  ./rt client show <N>     Show local client N and its QR code
  ./rt dns create          Create DNS records
  ./rt dns delete          Delete DNS records
  ./rt dns update          Update DNS records
  ./rt server create       Create the server
  ./rt server delete       Delete the server
  ./rt server ssh          SSH into server
  ./rt server status       Show the server status
  ./rt server sync         Sync local clients with server
  ./rt server update       Update the server
  ./rt setup               Run the initial setup
```
