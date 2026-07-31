#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# user_data.sh — EC2 bootstrap script
# Starts a Python web server on port 80 serving a static page
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

LOG="/var/log/user-data.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Lab Web Server Setup: $(date) ==="

# ── Create web root ───────────────────────────────────────────
mkdir -p /var/www/html

# ── Write the HTML page ───────────────────────────────────────
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AWS Broken Labs</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(to bottom, #1976D2, #1565C0);
      color: #e8eaed;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .container { text-align: center; padding: 2rem; }
    .logo {
      font-size: 0.85rem;
      font-weight: 600;
      letter-spacing: 0.2em;
      text-transform: uppercase;
      color: #ff9900;
      margin-bottom: 1rem;
    }
    h1 { font-size: 2.5rem; font-weight: 700; color: #ffffff; margin-bottom: 0.5rem; }
    h2 { font-size: 1.2rem; font-weight: 400; color: #9aa0a6; }
    .badge {
      display: inline-block;
      margin-top: 2rem;
      padding: 0.4rem 1rem;
      border: 1px solid #ff9900;
      border-radius: 4px;
      font-size: 0.8rem;
      color: #ff9900;
      letter-spacing: 0.1em;
    }
    .site-link {
      display: block;
      margin-top: 1rem;
      font-size: 0.8rem;
      color: #ff9900;
      text-decoration: none;
      letter-spacing: 0.05em;
    }
    .author {
      margin-top: 1.5rem;
      font-size: 0.75rem;
      color: #5f6368;
    }
  </style>
</head>
<body>
  <div class="container">
    <p class="logo">AWS Broken Labs</p>
    <h1>Lab Fixed! ✅</h1>
    <h2>If you can read this, the IGW route is working.</h2>
    <div class="badge">VPC Lab 01 &mdash; Internet Gateway Route</div>
    <p class="author">
      Terraform conversion by Emmanuel Mulenga &mdash;
      github.com/e-mulenga/broken-labs-vpc-lab-01
    </p>
  </div>
</body>
</html>
HTMLEOF

# ── Create systemd service ────────────────────────────────────
cat > /etc/systemd/system/lab-web.service << 'EOF'
[Unit]
Description=Broken Labs Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 80 --directory /var/www/html
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lab-web
systemctl start lab-web

if systemctl is-active --quiet lab-web; then
  echo "=== ✅ Web server started successfully ==="
else
  echo "=== ❌ Web server failed to start ==="
  journalctl -u lab-web --no-pager -n 20
  exit 1
fi
