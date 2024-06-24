#!/bin/bash

# Check for sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Prompt the user for input
LIGPORT=11601
read -p "Enter the Ligolo port (default 11601): " input
if [[ ! -z "$input" ]]; then
  LIGPORT=$input
fi
read -p "Enter the hostname: " HOSTNAME
read -p "Enter the SSH username: " SSH_USER
read -p "Enter the full path to the identity file: " IDENTITY_FILE


# Create a systemd service file for autossh
cat <<EOF > /etc/systemd/system/autossh_tunnel.service
[Unit]
Description=autossh Tunnel Service
After=network.target

[Service]
ExecStart=/usr/bin/autossh -M 20000 -vvv -N -T -L ${LIGPORT}:127.0.0.1:${LIGPORT} ${SSH_USER}@${HOSTNAME} -i ${IDENTITY_FILE}
RestartSec=20
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create a systemd service file for the agent
cat <<EOF > /etc/systemd/system/ligoloagent.service
[Unit]
Description=Ligolo Agent Service
After=network.target autossh_tunnel.service

[Service]
ExecStart=/usr/bin/agent -connect localhost:${LIGPORT} -ignore-cert
RestartSec=20
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply the new services
systemctl daemon-reload

# Enable the autossh service to start on boot
systemctl enable autossh_tunnel.service

# Enable the ligoloagent service to start on boot
systemctl enable ligoloagent.service

# Start the autossh service immediately
systemctl start autossh_tunnel.service

# Start the ligoloagent service immediately
systemctl start ligoloagent.service

echo "Services autossh_tunnel.service and ligoloagent.service created and started."
