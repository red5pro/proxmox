Before starting your install, you will need your Red5 Pro Server license and the download URL. Log into your account on https://account.red5.net/
and locate "Server License", copy the key string and save it for later. Now proceed to "Downloads", find the link under "Download the latest Red5 Pro Server", it may resemble this "Red5 Pro Server 14.3.1", right click and select "Copy link address", paste the contents where you saved your license string, you'll need both later. 

RED5PRO_LICENSE_KEY (required) - Your Red5 Pro license key
RED5PRO_DOWNLOAD_URL (required) - URL to download Red5 Pro zip file
RED5PRO_SSL_DOMAIN (optional) - Domain for SSL certificate
RED5PRO_SSL_EMAIL (optional) - Email for Let's Encrypt notifications

2049-7684-8851-2985
https://account.red5.net/download-server/red5pro-server-us-a3f390d88e-68.zip

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

  ✔️   Storage local (Free: 77.6GB  Used: 9.5GB) [Template]
  ✔️   Storage vm_big_data (Free: 19.1TB  Used: 329.9GB) [Container]
  ✔️   Template debian-12-standard_12.7-1_amd64.tar.zst [local]
  ✔️   LXC Container 106 was successfully created.

 ⚙️  Configuring VAAPI passthrough for LXC container
 ℹ️  VAAPI enables GPU hardware acceleration (e.g., for video transcoding in Jellyfin or Plex).

➤ Automatically mount all available VAAPI devices? [Y/n]: y
  ✔️   Started LXC Container
   💡   No network in LXC yet (try 1/10) – waiting...
  ✔️   Network in LXC is reachable (ping)
Extracting templates from packages: 100%
  ✔️   Customized LXC Container
  ✔️   Set up Container OS
  ✔️   Network Connected: 10.0.0.125 
  ✔️   IPv4 Internet Connected
   ✖️   IPv6 Internet Not Connected
  ✔️   Git DNS: github.com:(✔️ ) raw.githubusercontent.com:(✔️ ) api.github.com:(✔️ ) git.community-scripts.org:(✔️ )
  ✔️   Updated Container OS

