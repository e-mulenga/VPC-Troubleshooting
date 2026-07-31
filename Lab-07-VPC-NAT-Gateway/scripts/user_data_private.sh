#!/bin/bash
set -euo pipefail
LOG="/var/log/user-data.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Lab 07 Private Instance Setup: $(date) ==="

yum install -y amazon-ssm-agent 2>/dev/null || true
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "=== Testing outbound internet connectivity ==="
sleep 30  # Wait for NAT GW to be ready
if curl -s --max-time 15 https://aws.amazon.com > /dev/null 2>&1; then
  echo "SUCCESS: Internet access WORKING via NAT Gateway"
else
  echo "FAILED: Internet access BLOCKED - check NAT Gateway subnet placement"
fi

echo "=== Setup complete: $(date) ==="
