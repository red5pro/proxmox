#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025 mondain
# Author: Paul Gregoire (mondain)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/red5pro/proxmox

APP="Red5 Pro Server"
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/red5pro/proxmox/main/install/red5-install.sh"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/local/red5pro/ ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
  fi
  if ! command -v jq &>/dev/null; then
    $STD apt-get install -y jq
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/red5pro/proxmox/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  if [[ "${RELEASE}" != "$(cat ~/.red5pro)" ]] || [[ ! -f ~/.red5pro ]]; then
    msg_info "Stopping service"
    systemctl stop red5pro
    msg_ok "Service stopped"

    fetch_and_deploy_gh_release "red5pro" "red5pro/proxmox" "prebuild" "latest" "/usr/local/red5pro" "red5pro-server-*-release.zip"
    
    msg_info "Starting service"
    systemctl start red5pro
    msg_ok "Service started"

    msg_ok "Updated successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_info "Setting up Container"
msg_info "Installing Red5 Pro Server"
$STD pct exec $CTID -- bash -c "$(wget -qLO - ${INSTALL_SCRIPT_URL})"
msg_ok "Installed Red5 Pro Server"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access Red5 Pro Server at: ${CL}${BL}http://${IP}:5080${CL}\n"