# Red5 Pro Server - Proxmox LXC Helper Scripts

Automated installation scripts for deploying Red5 Pro Server on Proxmox Virtual Environment using LXC containers.

## Overview

This repository provides Proxmox helper scripts that automate the deployment of Red5 Pro Server in LXC containers. Red5 Pro is a real-time streaming server supporting WebRTC, RTMP, RTSP, HLS, and SRT protocols for ultra-low latency streaming applications.

## Features

- **Automated LXC Container Creation**: Pre-configured with optimal resources for Red5 Pro
- **Java 21 Installation**: Automatically installs required Java runtime
- **License Configuration**: Interactive prompt for Red5 Pro license key
- **Flexible Download Options**: Support for custom download URLs
- **Optional SSL/TLS**: Let's Encrypt certificate integration with automatic renewal
- **Systemd Service**: Red5 Pro configured as a system service with auto-start
- **Firewall Configuration**: Automatic UFW rules for all required ports
- **Update Support**: Built-in update mechanism for future releases

## Prerequisites

### Proxmox Environment
- Proxmox VE 8.x or higher
- Root access to Proxmox host
- Internet connectivity for package downloads

### Red5 Pro Requirements
- Valid Red5 Pro license key from https://account.red5.net/
- Red5 Pro server zip file hosted at an accessible URL

### Optional SSL Requirements
- Domain name pointing to your server's IP address
- Ports 80 and 443 accessible from the internet (for Let's Encrypt validation)
- Valid email address for certificate notifications

## Installation

### Quick Start

Run the following command on your Proxmox host:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/red5pro/proxmox/main/ct/red5install.sh)"
```

### Installation Prompts

During installation, you will be prompted for:

1. **Container Configuration** (optional - use defaults or customize):
   - CPU cores (default: 4)
   - RAM allocation (default: 4096 MB)
   - Disk size (default: 4 GB)
   - Network settings

2. **Red5 Pro License Key** (required):
   - Obtain from https://account.red5.net/

3. **Download Method** (required):
   - Option 1: Download from red5.net (requires account credentials - currently placeholder)
   - Option 2: Custom URL (recommended - provide direct link to Red5 Pro zip file)

4. **SSL Configuration** (optional):
   - Enable Let's Encrypt SSL certificate
   - Domain name
   - Email address for notifications

## Default Container Specifications

- **CPU**: 4 cores
- **RAM**: 4096 MB (4 GB)
- **Disk**: 4 GB
- **OS**: Debian 12
- **Type**: Unprivileged container
- **Category**: Media

## Network Ports

The following ports are configured and opened (if UFW is active):

| Port Range      | Protocol | Purpose           |
|-----------------|----------|-------------------|
| 5080            | TCP      | HTTP              |
| 443             | TCP      | HTTPS (if SSL)    |
| 1935            | TCP      | RTMP              |
| 8554            | TCP      | RTSP              |
| 8443            | TCP      | RTMPS (if SSL)    |
| 40000-65535     | UDP      | WebRTC            |

## Post-Installation

### Accessing Red5 Pro

After successful installation:

**Without SSL:**
- HTTP: `http://<container-ip>:5080`

**With SSL:**
- HTTP: `http://<domain>:5080`
- HTTPS: `https://<domain>`
- RTMPS: `rtmps://<domain>:8443`

### Service Management

Red5 Pro runs as a systemd service:

```bash
# Check service status
systemctl status red5pro

# Start service
systemctl start red5pro

# Stop service
systemctl stop red5pro

# Restart service
systemctl restart red5pro

# View logs
journalctl -u red5pro -f
```

### Red5 Pro Logs

Application logs are located at:
- `/usr/local/red5pro/log/red5.log`

## SSL Certificate Management

### Automatic Renewal

If SSL is configured during installation:
- Certificates automatically renew every 90 days via certbot
- Post-renewal hook regenerates Java keystores and truststores
- Red5 Pro service automatically restarts after renewal

### Manual Certificate Renewal

To manually renew certificates:

```bash
certbot renew
/etc/letsencrypt/renewal-hooks/post/red5pro-renew.sh
```

### SSL Files Location

Certificate files are stored at:
- `/etc/letsencrypt/live/<domain>/`
  - `fullchain.pem` - Full certificate chain
  - `privkey.pem` - Private key
  - `keystore.jks` - Java keystore
  - `truststore.jks` - Java truststore

## Configuration

### Red5 Pro Configuration Files

- **Main Config**: `/usr/local/red5pro/conf/red5-core.properties`
- **Service File**: `/lib/systemd/system/red5pro.service`
- **License File**: `/usr/local/red5pro/LICENSE.KEY`

### Modifying SSL Settings

SSL configuration is appended to `red5-core.properties`:

```properties
# HTTPS Configuration
https.port=443
https.keystorepass=changeit
https.keystorefile=/etc/letsencrypt/live/<domain>/keystore.jks
https.truststorepass=changeit
https.truststorefile=/etc/letsencrypt/live/<domain>/truststore.jks

# RTMPS Configuration
rtmps.port=8443
rtmps.keystorepass=changeit
rtmps.keystorefile=/etc/letsencrypt/live/<domain>/keystore.jks
rtmps.truststorepass=changeit
rtmps.truststorefile=/etc/letsencrypt/live/<domain>/truststore.jks
```

## Updating Red5 Pro

The container script includes an update function. To update Red5 Pro:

```bash
# From inside the container
/usr/local/bin/update
```

Note: The update mechanism requires GitHub releases to be published at `red5pro/proxmox` with assets matching the pattern `red5pro-server-*-release.zip`.

## Troubleshooting

### Installation Issues

**Certificate Generation Fails:**
- Verify domain DNS points to server IP
- Ensure ports 80 and 443 are accessible
- Check firewall rules on both Proxmox host and router
- Review certbot logs: `journalctl -u certbot`

**Service Won't Start:**
- Check Java installation: `java -version`
- Verify license key: `cat /usr/local/red5pro/LICENSE.KEY`
- Review service status: `systemctl status red5pro`
- Check logs: `tail -f /usr/local/red5pro/log/red5.log`

**Download Fails:**
- Verify custom URL is accessible
- Check network connectivity from container
- Ensure sufficient disk space

### Common Issues

**Port Already in Use:**
```bash
# Check what's using the port
ss -tulpn | grep :5080
```

**Permission Issues:**
```bash
# Verify Red5 Pro directory ownership
ls -la /usr/local/red5pro
```

**Java Heap Size:**
Edit `/lib/systemd/system/red5pro.service` and modify memory settings if needed.

## File Structure

```
proxmox/
├── ct/
│   └── red5install.sh          # Container creation script
├── install/
│   └── red5-install.sh         # Installation script (runs inside container)
├── frontend/
│   └── public/
│       └── json/
│           └── red5pro.json    # Metadata for helper scripts website
└── README.md                    # This file
```

## Repository Structure

This repository follows the Proxmox VE Helper-Scripts standard structure:

- **ct/**: Container creation scripts
- **install/**: Application installation scripts
- **frontend/public/json/**: Metadata files for web interface

## Development

### Testing Changes

When developing or testing modifications:

1. Fork this repository
2. Update script URLs to point to your fork
3. Test in a non-production Proxmox environment
4. Submit pull requests with changes

### Contributing

Contributions are welcome! Please ensure:
- Scripts follow existing coding standards
- Changes are tested on Proxmox VE 8.x+
- Documentation is updated accordingly

## Resources

### Red5 Pro Documentation
- Official Docs: https://www.red5.net/docs/
- SSL Configuration: https://www.red5.net/docs/installation/ssl/lets-encrypt/
- Account Portal: https://account.red5.net/

### Proxmox Resources
- Proxmox VE: https://www.proxmox.com/
- Community Scripts: https://community-scripts.github.io/ProxmoxVE/

### Let's Encrypt
- Certbot: https://certbot.eff.org/
- Documentation: https://letsencrypt.org/docs/

## License

MIT License - Copyright (c) 2025 mondain

See LICENSE file for details.

## Author

Paul Gregoire (mondain)

## Support

For issues related to:
- **These scripts**: Open an issue at https://github.com/red5pro/proxmox/issues
- **Red5 Pro Server**: Contact Red5 Pro support or visit https://www.red5.net/
- **Proxmox VE**: Visit https://forum.proxmox.com/

## Security Notes

- Default keystore/truststore password is `changeit` (Red5 Pro standard)
- License keys are stored in plain text at `/usr/local/red5pro/LICENSE.KEY`
- Ensure proper firewall rules to restrict access to management ports
- Keep Red5 Pro updated with latest security patches
- Use SSL/TLS for production deployments

## Disclaimer

This is an unofficial helper script for Red5 Pro Server. Red5 Pro is a commercial product requiring a valid license. Always review scripts before execution and test in non-production environments first.
