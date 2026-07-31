#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Lab 09 Setup: $(date) ==="
yum install -y amazon-ssm-agent aws-cli 2>/dev/null || true
systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
sleep 20
aws s3 ls --region us-east-1 > /dev/null 2>&1   && echo "SUCCESS: S3 access WORKING via VPC Endpoint"   || echo "FAILED: S3 access BLOCKED — check endpoint route table"
echo "=== Setup complete: $(date) ==="
