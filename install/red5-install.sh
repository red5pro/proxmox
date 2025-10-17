#!/usr/bin/env bash

# Copyright (c) 2025 mondain
# Author: Paul Gregoire (mondain)
# License: MIT | https://github.com/red5pro/proxmox/raw/main/LICENSE
# Source: https://github.com/red5pro/proxmox

# Source install functions from FUNCTIONS_FILE_PATH or fetch directly
if [ -n "$FUNCTIONS_FILE_PATH" ]; then
  source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
else
  # Fetch functions directly if not provided
  source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)
fi

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  unzip \
  jsvc \
  gnupg \
  ca-certificates \
  openssl \
  snapd
msg_ok "Installed Dependencies"

msg_info "Installing Java 21"
$STD apt-get install -y openjdk-21-jdk
msg_ok "Installed Java 21"

# Check for required environment variables
if [[ -z "$RED5PRO_LICENSE_KEY" ]]; then
    msg_error "RED5PRO_LICENSE_KEY environment variable is required!"
    msg_info "Please set it before running this script"
    exit 1
fi
LICENSE_KEY="$RED5PRO_LICENSE_KEY"
msg_ok "License key provided"

# Check for download URL
if [[ -z "$RED5PRO_DOWNLOAD_URL" ]]; then
    msg_error "RED5PRO_DOWNLOAD_URL environment variable is required!"
    msg_info "Please provide a URL to download the Red5 Pro server zip file"
    msg_info "You can download it from https://account.red5.net/ and host it yourself"
    exit 1
fi

msg_info "Downloading Red5 Pro Server from custom URL"
msg_info "Download URL: $RED5PRO_DOWNLOAD_URL"
cd /tmp
# Use wget with better timeout and retry settings
if ! wget --timeout=30 --tries=3 --retry-connrefused -O red5pro-server.zip "$RED5PRO_DOWNLOAD_URL" 2>&1; then
    msg_error "Failed to download Red5 Pro Server"
    msg_info "Error details above - common issues:"
    msg_info "  - Download link may have expired (generate a new one from account.red5.net)"
    msg_info "  - Network connectivity issues"
    msg_info "  - Server is temporarily unavailable (504 Gateway Timeout)"
    msg_info ""
    msg_info "Alternative: Host the zip file yourself and use that URL"
    exit 1
fi
msg_ok "Downloaded Red5 Pro Server"

msg_info "Installing Red5 Pro Server"
mkdir -p /usr/local/red5pro
cd /tmp
$STD unzip -o red5pro-server.zip -d /usr/local/red5pro
msg_ok "Installed Red5 Pro Server"

msg_info "Configuring Red5 Pro License"
# Create license file
echo "$LICENSE_KEY" > /usr/local/red5pro/LICENSE.KEY
chmod 644 /usr/local/red5pro/LICENSE.KEY
msg_ok "Configured Red5 Pro License"

msg_info "Setting up Red5 Pro systemd service"
# Configure red5pro.service file with correct paths
if [[ -f /usr/local/red5pro/red5pro.service ]]; then
    # Update JAVA_HOME in the service file
    JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))
    sed -i "s|Environment=\"JAVA_HOME=.*\"|Environment=\"JAVA_HOME=$JAVA_HOME_PATH\"|g" /usr/local/red5pro/red5pro.service
    sed -i "s|Environment=\"RED5_HOME=.*\"|Environment=\"RED5_HOME=/usr/local/red5pro\"|g" /usr/local/red5pro/red5pro.service

    # Copy service file
    cp /usr/local/red5pro/red5pro.service /lib/systemd/system/red5pro.service
    chmod 644 /lib/systemd/system/red5pro.service

    # Enable and start service
    systemctl daemon-reload
    systemctl enable red5pro.service
    systemctl start red5pro.service
    msg_ok "Set up Red5 Pro systemd service"
else
    msg_error "red5pro.service file not found in distribution!"
    msg_info "You may need to configure the service manually"
fi

msg_info "Configuring Firewall (if UFW is active)"
if systemctl is-active --quiet ufw; then
    $STD ufw allow 5080/tcp  # HTTP
    $STD ufw allow 443/tcp   # HTTPS
    $STD ufw allow 1935/tcp  # RTMP
    $STD ufw allow 8554/tcp  # RTSP
    $STD ufw allow 40000:65535/udp  # WebRTC
    msg_ok "Configured Firewall"
else
    msg_info "UFW not active, skipping firewall configuration"
fi

# Check for SSL configuration via environment variables
if [[ -n "$RED5PRO_SSL_DOMAIN" ]] && [[ -n "$RED5PRO_SSL_EMAIL" ]]; then
    msg_info "Configuring Let's Encrypt SSL"
    DOMAIN_NAME="$RED5PRO_SSL_DOMAIN"
    EMAIL_ADDRESS="$RED5PRO_SSL_EMAIL"

    msg_info "Installing Certbot via snap"
    $STD systemctl start snapd
    $STD systemctl enable snapd
    sleep 5
    $STD snap install core
    $STD snap refresh core
    $STD snap install --classic certbot
    $STD ln -sf /snap/bin/certbot /usr/bin/certbot
    msg_ok "Installed Certbot"

    msg_info "Stopping Red5 Pro service for certificate generation"
    systemctl stop red5pro
    msg_ok "Stopped Red5 Pro service"

    msg_info "Obtaining SSL certificate from Let's Encrypt"
    msg_info "This may take a few moments..."
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL_ADDRESS" \
        -d "$DOMAIN_NAME"

    if [[ $? -eq 0 ]]; then
        msg_ok "SSL certificate obtained successfully"

        CERT_PATH="/etc/letsencrypt/live/$DOMAIN_NAME"

        msg_info "Creating Java Keystore and Truststore"

        # Convert certificate to PKCS12
        openssl pkcs12 -export \
            -in "$CERT_PATH/fullchain.pem" \
            -inkey "$CERT_PATH/privkey.pem" \
            -out "$CERT_PATH/server.p12" \
            -name "$DOMAIN_NAME" \
            -password pass:changeit

        # Import PKCS12 into Java Keystore
        keytool -importkeystore \
            -deststorepass changeit \
            -destkeypass changeit \
            -destkeystore "$CERT_PATH/keystore.jks" \
            -srckeystore "$CERT_PATH/server.p12" \
            -srcstoretype PKCS12 \
            -srcstorepass changeit \
            -noprompt

        # Export certificate from keystore
        keytool -export \
            -alias "$DOMAIN_NAME" \
            -file "$CERT_PATH/red5pro.cer" \
            -keystore "$CERT_PATH/keystore.jks" \
            -storepass changeit \
            -noprompt

        # Import certificate into truststore
        keytool -import \
            -trustcacerts \
            -alias "$DOMAIN_NAME" \
            -file "$CERT_PATH/red5pro.cer" \
            -keystore "$CERT_PATH/truststore.jks" \
            -storepass changeit \
            -noprompt

        msg_ok "Created Keystore and Truststore"

        msg_info "Configuring Red5 Pro for SSL"

        # Update Red5 Pro configuration
        RED5_CONF="/usr/local/red5pro/conf/red5-core.properties"

        if [[ -f "$RED5_CONF" ]]; then
            # Backup original configuration
            cp "$RED5_CONF" "$RED5_CONF.backup"

            # Update SSL configuration
            cat >> "$RED5_CONF" << EOF

# SSL Configuration - Let's Encrypt
https.port=443
https.keystorepass=changeit
https.keystorefile=$CERT_PATH/keystore.jks
https.truststorepass=changeit
https.truststorefile=$CERT_PATH/truststore.jks

# RTMPS Configuration
rtmps.port=8443
rtmps.keystorepass=changeit
rtmps.keystorefile=$CERT_PATH/keystore.jks
rtmps.truststorepass=changeit
rtmps.truststorefile=$CERT_PATH/truststore.jks
EOF
            msg_ok "Configured Red5 Pro for SSL"
        else
            msg_error "Red5 Pro configuration file not found!"
            msg_info "Please configure SSL manually using files at: $CERT_PATH"
        fi

        msg_info "Setting up automatic certificate renewal"

        # Create renewal hook script
        cat > /etc/letsencrypt/renewal-hooks/post/red5pro-renew.sh << 'EOF'
#!/bin/bash
# Red5 Pro SSL Certificate Renewal Hook

DOMAIN_NAME=$(basename /etc/letsencrypt/live/*)
CERT_PATH="/etc/letsencrypt/live/$DOMAIN_NAME"

# Convert certificate to PKCS12
openssl pkcs12 -export \
    -in "$CERT_PATH/fullchain.pem" \
    -inkey "$CERT_PATH/privkey.pem" \
    -out "$CERT_PATH/server.p12" \
    -name "$DOMAIN_NAME" \
    -password pass:changeit

# Import PKCS12 into Java Keystore
rm -f "$CERT_PATH/keystore.jks"
keytool -importkeystore \
    -deststorepass changeit \
    -destkeypass changeit \
    -destkeystore "$CERT_PATH/keystore.jks" \
    -srckeystore "$CERT_PATH/server.p12" \
    -srcstoretype PKCS12 \
    -srcstorepass changeit \
    -noprompt

# Export and import for truststore
keytool -export \
    -alias "$DOMAIN_NAME" \
    -file "$CERT_PATH/red5pro.cer" \
    -keystore "$CERT_PATH/keystore.jks" \
    -storepass changeit \
    -noprompt

rm -f "$CERT_PATH/truststore.jks"
keytool -import \
    -trustcacerts \
    -alias "$DOMAIN_NAME" \
    -file "$CERT_PATH/red5pro.cer" \
    -keystore "$CERT_PATH/truststore.jks" \
    -storepass changeit \
    -noprompt

# Restart Red5 Pro
systemctl restart red5pro
EOF

        chmod +x /etc/letsencrypt/renewal-hooks/post/red5pro-renew.sh
        msg_ok "Set up automatic certificate renewal"

        msg_info "Starting Red5 Pro service with SSL"
        systemctl start red5pro
        msg_ok "Started Red5 Pro service"

        msg_ok "SSL configuration completed successfully!"
        msg_info "Your Red5 Pro server is now accessible at:"
        msg_info "  HTTP:  http://$DOMAIN_NAME:5080"
        msg_info "  HTTPS: https://$DOMAIN_NAME"
        msg_info "  RTMPS: rtmps://$DOMAIN_NAME:8443"
        msg_info ""
        msg_info "SSL certificates will auto-renew every 90 days"

    else
        msg_error "Failed to obtain SSL certificate"
        msg_info "Please ensure:"
        msg_info "  - Domain $DOMAIN_NAME points to this server's IP"
        msg_info "  - Ports 80 and 443 are accessible from the internet"
        msg_info "  - No firewall is blocking Let's Encrypt validation"
        msg_info "Starting Red5 Pro without SSL..."
        systemctl start red5pro
    fi
else
    msg_info "Skipping SSL configuration"
fi

# Store version information
if [[ -d /usr/local/red5pro ]]; then
    echo "$(date +%Y%m%d)" > ~/.red5pro
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -f /tmp/red5pro-server.zip
msg_ok "Cleaned"
