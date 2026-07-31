#!/bin/bash
set -euo pipefail
LOG="/var/log/user-data.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Lab 04 Web Server Setup: $(date) ==="

mkdir -p /var/www/html

cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AWS Broken Labs — Lab 04</title>
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
    .logo { font-size: 0.85rem; font-weight: 600; letter-spacing: 0.2em;
            text-transform: uppercase; color: #ff9900; margin-bottom: 1rem; }
    h1 { font-size: 2.5rem; font-weight: 700; color: #ffffff; margin-bottom: 0.5rem; }
    h2 { font-size: 1.2rem; font-weight: 400; color: #9aa0a6; }
    .badge { display: inline-block; margin-top: 2rem; padding: 0.4rem 1rem;
             border: 1px solid #ff9900; border-radius: 4px; font-size: 0.8rem;
             color: #ff9900; letter-spacing: 0.1em; }
    .author { margin-top: 1.5rem; font-size: 0.75rem; color: #5f6368; }
  </style>
</head>
<body>
  <div class="container">
    <p class="logo">AWS Broken Labs</p>
    <h1>Lab 04 Fixed! ✅</h1>
    <h2>Subnet is now associated to the correct route table.</h2>
    <div class="badge">VPC Lab 04 &mdash; Route Table Association</div>
    <p class="author">Terraform conversion by Emmanuel Mulenga &mdash; github.com/e-mulenga</p>
  </div>
</body>
</html>
HTMLEOF

cat > /etc/systemd/system/lab-web.service << 'EOF'
[Unit]
Description=Broken Labs Lab 04 Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 80 --directory /var/www/html
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lab-web
systemctl start lab-web

systemctl is-active --quiet lab-web \
  && echo "=== ✅ Web server started ===" \
  || { echo "=== ❌ Web server failed ==="; journalctl -u lab-web -n 20; exit 1; }
