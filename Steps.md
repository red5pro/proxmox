Log into your Proxmox server
Select your datacenter
Select Shell
Paste the script line from our github and press enter: 

bash -c "$(wget -qLO - https://raw.githubusercontent.com/red5pro/proxmox/main/ct/red5install.sh)"

Select Advanced Settings
Select Privileged
Set your root password, this will be needed when SSH into the container
Go with default options for all the remaining questions, unless your install requires a specific option
After all the initial questions are completed, the review will appear like this:

  🧩  Using Advanced Settings on node orleans
  🖥️  Operating System: debian
  🌟  Version: 12
  📦  Container Type: Privileged
  🔐  Root Password: ********
  🆔  Container ID: 106
  🏠  Hostname: red5proserver
  💾  Disk Size: 4 GB
  🧠  CPU Cores: 4
  🛠️  RAM Size: 4096 MiB
  🌉  Bridge: vmbr0
  📡  IPv4: DHCP
  📡  IPv6: SLAAC/AUTO
  📡  APT-Cacher IP Address: Default
  ⚙️  Interface MTU Size: Default
  🔍  DNS Search Domain: Host
  📡  DNS Server IP Address: Host
  🏷️  Vlan: Default
  📡  Tags: community-script;media
  🔑  Root SSH Access: no
  🗂️  Enable FUSE Support: no
  🔍  Verbose Mode: no
  🚀  Creating a Red5 Pro Server LXC using the above advanced settings

Then the install moves on to Storage Pools, select where you'll want your disk space
When you come to the VAAPI option, select Y if you'll be using video accellerated features

