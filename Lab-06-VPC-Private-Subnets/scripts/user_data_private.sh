#!/bin/bash
set -euo pipefail
LOG="/var/log/user-data.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Lab 06 Private Instance Setup: $(date) ==="

# Install SSM agent (should already be on AL2023)
yum install -y amazon-ssm-agent 2>/dev/null || true
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "=== Testing outbound internet connectivity ==="
if curl -s --max-time 10 https://aws.amazon.com > /dev/null 2>&1; then
  echo "✅ Internet access: WORKING (NAT Gateway configured)"
else
  echo "❌ Internet access: FAILED (NAT Gateway missing or not ready)"
fi

echo "=== Setup complete: $(date) ==="
