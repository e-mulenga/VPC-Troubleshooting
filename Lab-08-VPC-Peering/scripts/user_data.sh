#!/bin/bash
set -euo pipefail
LOG="/var/log/user-data.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Lab 08 Instance Setup: $(date) ==="

yum install -y amazon-ssm-agent 2>/dev/null || true
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install ping utility
yum install -y iputils 2>/dev/null || true

echo "=== Setup complete: $(date) ==="
echo "Connect via SSM and ping the other instance's private IP to test peering."
